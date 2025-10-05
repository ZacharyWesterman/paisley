--TEMP: read bytecode from stdin. only for testing
-- INSTRUCTIONS = {}
-- CURRENT_INSTRUCTION = 0
-- LAST_CMD_RESULT = nil
-- RANDOM_SEED = 0 --Change this later
MAX_ITER = 100 --Max number of instructions to run before pausing execution (performance reasons mostly)

NULL = {}
-- STACK = {}
-- VARS = {}

--[[minify-delete]]
require 'src.util.filesystem'

local function runtime_error(line, msg)
	if msg:sub(1, 11) == 'RUNTIME BUG' then
		msg = msg .. '\nTHIS IS A BUG IN THE PAISLEY COMPILER, PLEASE REPORT IT!'
	end

	if FILE ~= nil and FILE ~= '' then
		print(FILE .. ': ' .. line .. ': ' .. msg)
	else
		print(line .. ': ' .. msg)
	end
	error('ERROR in user-supplied Paisley script.')
end

---Pop the top value off of the data stack.
---@return any
local function POP()
	local val = STACK[#STACK]
	table.remove(STACK)
	if val == NULL then return nil end
	return val
end

---Push a value onto the top of the data stack.
---@param value any
local function PUSH(value)
	if value == nil then
		table.insert(STACK, NULL)
	elseif type(value) == 'table' then
		--DEEP COPY tables into the stack. It's slower, but it prevents data from randomly mutating!
		local result, i = setmetatable({}, getmetatable(value))
		local meta = getmetatable(result)

		if meta and not meta.is_array then
			for key, val in pairs(value) do result[key] = val end
		else
			for i = 1, #value do
				table.insert(result, value[i])
			end
		end

		table.insert(STACK, result)
	else
		table.insert(STACK, value)
	end
end

--[[c=math]]
local function mathfunc(funcname)
	return function(line)
		local v, p = POP(), {}
		for i = 1, #v do
			table.insert(p, std.num(v[i]))
		end

		---@diagnostic disable-next-line
		local u = table.unpack or unpack

		--If null was passed to the function, in a way that could not be determined at compile time, coerce it to be zero.
		if #p == 0 then
			print('WARNING: line ' .. line .. ': Null passed to math function, coerced to 0')
			p = { 0 }
		end

		local fn = math[funcname]
		if not fn then
			runtime_error(line, 'RUNTIME BUG: Math function "' .. funcname .. '" does not exist')
		end

		local val1, val2 = fn(u(p))
		if val2 then
			PUSH({ val1, val2 })
		else
			PUSH(val1)
		end
	end
end
--[[/]]

--[[c=numbers]]
---Format two parameters and perform a binary operation on them.
---@param format_func fun(param: any): any The function to format the parameters with.
---@param operate_func fun(param1: any, param2: any): any The operation to perform on the two parameters.
---@return fun(line: number): nil runtime_function The function to execute the operation.
local function operator(format_func, operate_func)
	return function(line)
		local v2, v1 = POP(), POP()

		if type(v1) == 'table' or type(v2) == 'table' then
			if type(v1) ~= 'table' then v1 = { v1 } end
			if type(v2) ~= 'table' then v2 = { v2 } end

			local result = {}
			for i = 1, math.min(#v1, #v2) do
				table.insert(result, operate_func(format_func(v1[i]), format_func(v2[i])))
			end
			PUSH(result)
		else
			PUSH(operate_func(format_func(v1), format_func(v2)))
		end
	end
end
--[[/]]

--[[c=sets]]
---Perform operations on two sets.
---@param func fun(a: table, b: table): table The function to perform on the two sets.
---@return fun(line: number): nil runtime_function The function to execute the operation.
local function set_operator(func)
	return function(line)
		local v = POP()
		local a, b = v[1], v[2]
		if type(a) ~= 'table' then a = { a } end
		if type(b) ~= 'table' then b = { b } end
		PUSH(func(a, b))
	end
end

local functions = {
	--JUMP
	function(line, param)
		if param == nil then
			CURRENT_INSTRUCTION = POP()
		else
			CURRENT_INSTRUCTION = param
		end
	end,

	--JUMP IF NIL
	function(line, param)
		if STACK[#STACK] == NULL then
			CURRENT_INSTRUCTION = param
		end
	end,

	--JUMP IF FALSEY
	function(line, param)
		if std.bool(STACK[#STACK]) == false then CURRENT_INSTRUCTION = param end
	end,

	--EXPLODE: only used in for loops
	function(line, param)
		local array = POP()

		if std.type(array) == 'object' then
			for key, value in pairs(array) do PUSH(key) end
		elseif std.type(array) == 'array' then
			for i = 1, #array do
				local val = array[#array - i + 1]
				PUSH(val)
			end
		else
			PUSH(array)
		end
	end,

	--IMPLODE
	function(line, param)
		--Reverse the table so it's in the correct order
		local res = {}
		for i = param, 1, -1 do
			res[i] = POP()
		end
		PUSH(res)
	end,

	--SUPERIMPLODE
	function(line, param)
		local array = {}
		for i = 1, param do
			local val = POP()
			if type(val) == 'table' then
				local k
				for k = 1, #val do table.insert(array, val[k]) end
			else
				table.insert(array, val)
			end
		end
		--Reverse the table so it's in the correct order
		local res = {}
		for i = 1, #array do
			table.insert(res, array[#array - i + 1])
		end
		PUSH(res)
	end,

	--ADD
	operator(std.num, function(a, b) return a + b end),

	--SUB
	operator(std.num, function(a, b) return a - b end),

	--MUL
	operator(std.num, function(a, b) return a * b end),

	--DIV
	operator(std.num, function(a, b) return a / b end),

	--REM
	operator(std.num, function(a, b) return a % b end),

	--LENGTH
	function()
		local val = POP()
		if type(val) == 'table' then PUSH(#val) else PUSH(#std.str(val)) end
	end,

	--ARRAY INDEX
	function(line)
		local index, data = POP(), POP()
		local is_string = false
		if type(data) ~= 'table' then
			is_string = true
			data = std.split(std.str(data), '')
		end
		local meta = getmetatable(data)
		local is_array = true
		if meta and not meta.is_array then is_array = false end

		local result
		if type(index) ~= 'table' then
			if is_array then
				if type(index) ~= 'number' and not tonumber(index) then
					print('WARNING: line ' .. line .. ': Attempt to index array with non-numeric value, null returned')
					PUSH(NULL)
					return
				end

				index = std.num(index)
				if index < 0 then
					index = #data + index + 1
				elseif index == 0 then
					print('WARNING: line ' .. line .. ': Indexes begin at 1, not 0')
				end

				result = data[index]
			else
				result = data[std.str(index)]
			end
		else
			result = {}
			for i = 1, #index do
				if is_array then
					if type(index[i]) ~= 'number' and not tonumber(index[i]) then
						print('WARNING: line ' ..
							line .. ': Attempt to index array with non-numeric value, null returned')
						PUSH(NULL)
						return
					end

					local ix = std.num(index[i])
					if ix < 0 then
						ix = #data + ix + 1
					elseif ix == 0 then
						print('WARNING: line ' .. line .. ': Indexes begin at 1, not 0')
					end
					table.insert(result, data[ix])
				else
					table.insert(result, data[std.str(index[i])])
				end
			end
			if is_string then result = std.join(result, '') end
		end
		PUSH(result)
	end,

	--ARRAYSLICE
	function(line)
		local stop, start, i = std.num(POP()), std.num(POP())
		local array = {}

		--For performance, limit how big slices can be.
		if stop - start > std.MAX_ARRAY_LEN then
			print('WARNING: line ' ..
				line ..
				': Attempt to create an array of ' ..
				(stop - start) .. ' elements (max is ' .. std.MAX_ARRAY_LEN .. '). Array truncated.')
			stop = start + std.MAX_ARRAY_LEN
		end

		for i = start, stop do
			table.insert(array, i)
		end
		PUSH(array)
	end,

	--CONCAT
	function(line, param)
		local result = ''
		while param > 0 do
			result = std.str(POP()) .. result
			param = param - 1
		end
		PUSH(result)
	end,

	--BOOLEAN AND
	operator(std.bool, function(a, b) return a and b end),

	--BOOLEAN OR
	operator(std.bool, function(a, b) return a or b end),

	--BOOLEAN XOR
	operator(std.bool, function(a, b) return (a or b) and not (a and b) end),

	--IN ARRAY/STRING
	function()
		local data, val = POP(), POP()
		local result = false
		if std.type(data) == 'array' then
			for i = 1, #data do
				if data[i] == val then
					result = true
					break
				end
			end
		elseif std.type(data) == 'object' then
			result = data[std.str(val)] ~= nil
		else
			result = std.contains(std.str(data), val)
		end
		PUSH(result)
	end,

	--STRING LIKE PATTERN
	operator(std.str, function(a, b) return a:match(b) ~= nil end),

	--EQUAL
	function() PUSH(std.equal(POP(), POP())) end,

	--NOT EQUAL
	function() PUSH(not std.equal(POP(), POP())) end,

	--GREATER THAN
	function() PUSH(std.compare(POP(), POP(), function(p1, p2) return p1 < p2 end)) end,

	--GREATER THAN OR EQUAL
	function() PUSH(std.compare(POP(), POP(), function(p1, p2) return p1 <= p2 end)) end,

	--LESS THAN
	function() PUSH(std.compare(POP(), POP(), function(p1, p2) return p1 > p2 end)) end,

	--LESS THAN OR EQUAL
	function() PUSH(std.compare(POP(), POP(), function(p1, p2) return p1 >= p2 end)) end,

	--BOOLEAN NOT
	function() PUSH(not std.bool(POP())) end,

	--CHECK IF VARIABLE EXISTS
	function() PUSH(VARS[POP()] ~= nil) end,

	--IRANDOM
	function()
		local v = POP()
		local min, max = std.num(v[1]), std.num(v[2])
		PUSH(math.random(math.floor(min), math.floor(max)))
	end,

	--FRANDOM
	function()
		local v = POP()
		local max, min = std.num(v[1]), std.num(v[2])
		PUSH((math.random() * (max - min)) + min)
	end,

	--WORD DIFF (Levenshtein distance)
	function()
		local v = POP()
		PUSH(lev(std.str(v[1]), std.str(v[2])))
	end,

	--DIST (N-dimensional vector distance)
	function()
		local v = POP()
		local b, a = v[1], v[2]
		local t1, t2 = type(a), type(b)
		local result

		if t1 ~= 'table' and t2 == 'table' then
			b = b[1]
		elseif t1 == 'table' and t2 ~= 'table' then
			a = a[1]
		end

		if t1 == 'table' then
			local total = 0
			for i = 1, math.min(#a, #b) do
				local p = a[i] - b[i]
				total = total + p * p
			end
			result = math.sqrt(total)
		else
			result = math.abs(b - a)
		end
		PUSH(result)
	end,

	--MATH FUNCTIONS
	mathfunc('sin'),
	mathfunc('cos'),
	mathfunc('tan'),
	mathfunc('asin'),
	mathfunc('acos'),
	mathfunc('atan'),
	mathfunc('atan2'),
	mathfunc('sqrt'),

	--SUM
	function()
		local v, total = POP(), 0
		for i = 1, #v do
			if type(v[i]) == 'table' then
				for k = 1, #v[i] do total = total + std.num(v[i][k]) end
			else
				total = total + std.num(v[i])
			end
		end
		PUSH(total)
	end,

	--MULT
	function()
		local v, total = POP(), 1
		for i = 1, #v do
			if type(v[i]) == 'table' then
				for k = 1, #v[i] do
					total = total * std.num(v[i][k])
					if total == 0 then break end
				end
			else
				total = total * std.num(v[i])
			end
			if total == 0 then break end
		end
		PUSH(total)
	end,

	--POWER
	operator(std.num, function(a, b) if a == 0 then return 0 else return a ^ b end end),

	--MIN of arbitrary number of arguments
	function()
		local v, target = POP()

		for i = 1, #v do
			if type(v[i]) == 'table' then
				for k = 1, #v[i] do
					if target then target = math.min(target, std.num(v[i][k])) else target = std.num(v[i][k]) end
				end
			else
				if target then target = math.min(target, std.num(v[i])) else target = std.num(v[i]) end
			end
		end
		PUSH(target)
	end,

	--MAX of arbitrary number of arguments
	function()
		local v, target = POP()

		for i = 1, #v do
			if type(v[i]) == 'table' then
				for k = 1, #v[i] do
					if target then target = math.max(target, std.num(v[i][k])) else target = std.num(v[i][k]) end
				end
			else
				if target then target = math.max(target, std.num(v[i])) else target = std.num(v[i]) end
			end
		end
		PUSH(target)
	end,

	--SPLIT string into array
	function()
		local v = POP()
		PUSH(std.split(std.str(v[1]), std.str(v[2])))
	end,

	--JOIN array into string
	function()
		local v = POP()
		PUSH(std.join(v[1], std.str(v[2])))
	end,

	--TYPE
	function() PUSH(std.type(POP()[1])) end,

	--BOOL
	function() PUSH(std.bool(POP())) end,

	--NUM
	function() PUSH(std.num(POP()[1])) end,

	--STR
	function() PUSH(std.str(POP()[1])) end,

	--MORE MATH FUNCTIONS
	mathfunc('floor'),
	mathfunc('ceil'),

	--ROUND
	function() PUSH(math.floor(std.num(POP()[1]) + 0.5)) end,

	mathfunc('abs'),

	--ARRAY APPEND
	function()
		local v = POP()
		if type(v[1]) == 'table' then
			table.insert(v[1], v[2])
			PUSH(v[1])
		else
			PUSH({ v[1], v[2] })
		end
	end,

	--INDEX
	function()
		local v = POP()
		local res
		if type(v[1]) == 'table' then
			res = std.arrfind(v[1], v[2], 1)
		else
			res = std.strfind(std.str(v[1]), std.str(v[2]), 1)
		end
		PUSH(res)
	end,

	--LOWERCASE
	function() PUSH(std.str(POP()):lower()) end,

	--UPPERCASE
	function() PUSH(std.str(POP()):upper()) end,

	--CAMEL CASE
	function()
		local v = std.str(POP())
		PUSH(v:gsub('(%l)(%w*)', function(x, y) return x:upper() .. y end))
	end,

	--STRING REPLACE
	function()
		local v = POP()
		PUSH(std.join(std.split(std.str(v[1]), std.str(v[2])), std.str(v[3])))
	end,

	--JSON_ENCODE
	function(line)
		local v = POP()
		local indent = nil
		if std.bool(v[2]) then indent = 2 end

		local res, err = json.stringify(v[1], indent, true)
		if err ~= nil then
			runtime_error(line, err)
		end
		PUSH(res)
	end,

	--JSON_DECODE
	function(line)
		local v = POP()

		if type(v[1]) ~= 'string' then
			runtime_error(line, 'Input to json_decode is not a string')
		end

		local res, err = json.parse(v[1], true)
		if err ~= nil then
			runtime_error(line, err)
		end

		PUSH(res)
	end,

	--JSON_VALID
	function()
		local v = POP()
		if type(v[1]) ~= 'string' then
			PUSH(false)
		else
			PUSH(json.verify(v[1]))
		end
	end,

	--BASE64_ENCODE
	function()
		PUSH(std.b64_encode(std.str(POP()[1])))
	end,

	--BASE64_DECODE
	function()
		PUSH(std.b64_decode(std.str(POP()[1])))
	end,

	--LEFT PAD STRING
	function()
		local v = POP()
		local text = std.str(v[1])
		local character = std.str(v[2]):sub(1, 1)
		local width = std.num(v[3])

		PUSH(character:rep(width - #text) .. text)
	end,

	--RIGHT PAD STRING
	function()
		local v = POP()
		local text = std.str(v[1])
		local character = std.str(v[2]):sub(1, 1)
		local width = std.num(v[3])

		PUSH(text .. character:rep(width - #text))
	end,

	--FILTER STRING CHARS BASED ON PATTERN
	function()
		local v = POP()
		PUSH(std.filter(std.str(v[1]), std.str(v[2])))
	end,

	--GET ALL PATTERN MATCHES
	function()
		local v = POP()
		local array = std.array()
		print(json.stringify(std.str(v[1]):gmatch("^%d+")()))
		for i in std.str(v[1]):gmatch(std.str(v[2])) do
			table.insert(array, i)
		end
		PUSH(array)
	end,

	--SPLIT A NUMBER INTO CLOCK TIME
	function()
		local v = std.num(POP()[1])
		local result = {
			math.floor(v / 3600),
			math.floor(v / 60) % 60,
			math.floor(v) % 60,
		}
		local millis = math.floor(v * 1000) % 1000
		if millis ~= 0 then result[4] = millis end
		PUSH(result)
	end,

	--REVERSE ARRAY OR STRING
	function()
		local v = POP()[1]
		if type(v) == 'string' then
			PUSH(v:reverse())
			return
		elseif type(v) ~= 'table' then
			PUSH({ v })
			return
		end

		local result = {}
		for i = #v, 1, -1 do
			table.insert(result, v[i])
		end

		PUSH(result)
	end,
	--SORT ARRAY
	function()
		local is_table, v = false, POP()[1]
		if type(v) ~= 'table' then
			PUSH({ v })
			return
		end

		for key, val in pairs(v) do
			if type(val) == 'table' then
				is_table = true
				break
			end
		end

		if is_table then
			table.sort(v, function(a, b) return std.str(a) < std.str(b) end)
		else
			table.sort(v)
		end
		PUSH(v)
	end,

	--BYTES FROM NUMBER
	function()
		local v = POP()
		local result = {}
		local value = math.floor(std.num(v[1]))
		for i = math.min(4, std.num(v[2])), 1, -1 do
			result[i] = value % 256
			value = math.floor(value / 256)
		end
		PUSH(result)
	end,

	--NUMBER FROM BYTES
	function()
		local v = POP()
		if type(v[1]) ~= 'table' then
			PUSH(0)
		else
			local result = 0
			for i = 1, #v[1] do
				result = result * 256 + v[1][i]
			end
			PUSH(result)
		end
	end,

	--MERGE TWO ARRAYS
	function()
		local v = POP()
		if type(v[1]) ~= 'table' then v[1] = { v[1] } end
		if type(v[2]) ~= 'table' then v[2] = { v[2] } end

		for i = 1, #v[2] do
			table.insert(v[1], v[2][i])
		end
		PUSH(v[1])
	end,

	--UPDATE ELEMENT IN ARRAY
	function()
		local v = POP()
		local object, indices, value, is_string = v[1], v[2], v[3], false

		--Only valid for arrays, objects, or strings
		if type(object) == 'string' then
			is_string = true
			object = std.split(object, '')
		elseif type(object) ~= 'table' then
			PUSH(object)
			return
		end

		if type(indices) ~= 'table' then indices = { indices } end
		if #indices == 0 then
			PUSH(object)
			return
		end

		--Narrow down to sub-object
		local sub_object = object
		for i = 1, #indices - 1 do
			local ix, tp = indices[i], std.type(sub_object)
			if tp == 'object' then
				ix = std.str(ix)
			elseif tp ~= 'array' then
				PUSH(object)
				return
			else
				ix = std.num(ix)
				if ix < 0 then ix = #sub_object + ix + 1 end
			end

			if sub_object[ix] == nil then
				--We can only set the bottom-level object
				PUSH(object)
				return
			end

			sub_object = sub_object[ix]
		end


		local ix, tp = indices[#indices], std.type(sub_object)
		if tp == 'object' then
			ix = std.str(ix)
			sub_object[ix] = value
		elseif tp == 'array' then
			ix = std.num(ix)
			if ix < 0 then ix = #sub_object + ix + 1 end
			if ix > 0 then
				sub_object[ix] = value
			else
				table.insert(sub_object, 1, value)
			end
		end

		PUSH(object)
	end,

	--INSERT ELEMENT IN ARRAY
	function()
		local v = POP()
		if type(v[1]) ~= 'table' then v[1] = { v[1] } end
		local n = std.num(v[2])

		local meta = getmetatable(v[1])
		if not meta or meta.is_array then
			--If index is negative, insert starting at the end
			if n < 0 then n = #v[1] + n + 2 end

			if n > #v[1] then
				table.insert(v[1], v[3])
			elseif n > 0 then
				table.insert(v[1], n, v[3])
			else
				--Insert at beginning if index is less than 1
				table.insert(v[1], 1, v[3])
			end
		end
		PUSH(v[1])
	end,

	--DELETE ELEMENT FROM ARRAY
	function()
		local v = POP()
		if type(v[1]) ~= 'table' then v[1] = { v[1] } end
		table.remove(v[1], std.num(v[2]))
		PUSH(v[1])
	end,

	--LINEAR INTERPOLATION
	function()
		local v = POP()
		local perc, a, b = std.num(v[1]), std.num(v[2]), std.num(v[3])
		PUSH(a + perc * (b - a))
	end,

	--SELECT RANDOM ELEMENT FROM ARRAY
	function()
		local v = POP()
		if type(v[1]) ~= 'table' then
			PUSH(v[1])
		else
			PUSH(v[1][math.random(1, #v[1])])
		end
	end,

	--GENERATE SHA256 HASH OF A STRING
	function()
		PUSH(std.hash(std.str(POP()[1])))
	end,

	--FOLD ARRAY INTO OBJECT
	function()
		local result, array = std.object(), POP()[1]
		if type(array) == 'table' then
			for i = 1, #array, 2 do
				result[std.str(array[i])] = array[i + 1]
			end
		end
		PUSH(result)
	end,

	--UNFOLD OBJECT INTO ARRAY
	function()
		local result, object = {}, POP()[1]
		if type(object) == 'table' then
			for key, value in pairs(object) do
				table.insert(result, key)
				table.insert(result, value)
			end
		end
		PUSH(result)
	end,

	--GET OBJECT KEYS
	function()
		local result, object = {}, POP()[1]
		if type(object) == 'table' then
			for key, value in pairs(object) do
				table.insert(result, key)
			end
		end
		PUSH(result)
	end,

	--GET OBJECT VALUES
	function()
		local result, object = {}, POP()[1]
		if type(object) == 'table' then
			for key, value in pairs(object) do
				table.insert(result, value)
			end
		end
		PUSH(result)
	end,

	--GET OBJECT KEY-VALUE PAIRS
	function()
		local result, object = {}, POP()[1]
		if type(object) == 'table' then
			for key, value in pairs(object) do
				table.insert(result, { key, value })
			end
		end
		PUSH(result)
	end,

	--INTERLEAVE TWO ARRAYS
	function()
		local result, v = {}, POP()
		if type(v[1]) == 'table' and type(v[2]) == 'table' then
			local length = math.min(#v[1], #v[2])
			for i = 1, length do
				table.insert(result, v[1][i])
				table.insert(result, v[2][i])
			end
			for i = length + 1, #v[1] do table.insert(result, v[1][i]) end
			for i = length + 1, #v[2] do table.insert(result, v[2][i]) end
		elseif type(v[1]) == 'table' then
			result = v[1]
		elseif type(v[2]) == 'table' then
			result = v[2]
		end
		PUSH(result)
	end,

	--FILTER UNIQUE ELEMENTS IN ARRAY
	function()
		local v = POP()[1]
		if type(v) == 'table' then
			PUSH(std.unique(v))
		else
			PUSH { v }
		end
	end,

	--UNION OF TWO SETS
	set_operator(std.union),

	--INTERSECTION OF TWO SETS
	set_operator(std.intersection),

	--DIFFERENCE OF TWO SETS
	set_operator(std.difference),

	--SYMMETRIC DIFFERENCE OF TWO SETS
	set_operator(std.symmetric_difference),

	--CHECK IF TWO SETS ARE DISJOINT
	set_operator(std.is_disjoint),

	--CHECK IF ONE SET IS A SUBSET OF ANOTHER
	set_operator(std.is_subset),

	--CHECK IF ONE SET IS A SUPERSET OF ANOTHER
	set_operator(std.is_superset),

	--COUNT OCCURRENCES OF A VALUE IN ARRAY OR SUBSTRING IN STRING
	function()
		local v = POP()
		local res
		if type(v[1]) == 'table' then
			res = std.arrcount(v[1], v[2])
		else
			res = std.strcount(std.str(v[1]), std.str(v[2]))
		end
		PUSH(res)
	end,

	--FIND NTH OCCURRENCE OF A VALUE IN ARRAY OR SUBSTRING IN STRING
	function()
		local v = POP()
		local res
		if type(v[1]) == 'table' then
			res = std.arrfind(v[1], v[2], std.num(v[3]))
		else
			res = std.strfind(std.str(v[1]), std.str(v[2]), std.num(v[3]))
		end
		PUSH(res)
	end,

	--FLATTEN AN ARRAY OF ANY DIMENSION TO A 1-DIMENSIONAL ARRAY
	function()
		local function flatten(array)
			local result = std.array()
			for i = 1, #array do
				if type(array[i]) == 'table' then
					local flat = flatten(array[i])
					for k = 1, #flat do table.insert(result, flat[k]) end
				else
					table.insert(result, array[i])
				end
			end
			return result
		end

		PUSH(flatten(POP()))
	end,

	--SMOOTHSTEP
	function()
		local v = POP()
		local value, min, max = std.num(v[1]), std.num(v[2]), std.num(v[3])

		local range = max - min
		value = (math.min(math.max(min, value), max) - min) / range
		value = value * value * (3.0 - 2.0 * value)
		PUSH(value * range + min)
	end,

	--HYPERBOLIC TRIG FUNCTIONS
	mathfunc('sinh'),
	mathfunc('cosh'),
	mathfunc('tanh'),

	--SIGN OF A NUMBER
	function() PUSH(std.sign(std.num(POP()[1]))) end,

	--CHAR TO ASCII
	function() PUSH(string.byte(std.str(POP()[1]))) end,

	--ASCII TO CHAR
	function() PUSH(string.char(std.num(POP()[1]))) end,

	--STRING BEGINS WITH
	function()
		local v = POP()
		local search, substring = std.str(v[1]), std.str(v[2])
		PUSH(search:sub(1, #substring) == substring)
	end,

	--STRING ENDS WITH
	function()
		local v = POP()
		local search, substring = std.str(v[1]), std.str(v[2])
		PUSH(search:sub(#search - #substring + 1, #search) == substring)
	end,

	--CONVERT NUMBER TO NUMERIC STRING
	function()
		local v = POP()
		local number, base, pad_width = std.num(v[1]), std.num(v[2]), std.num(v[3])
		PUSH(std.to_base(number, base, pad_width))
	end,

	--CONVERT TIMESTAMP INTO TIME STRING
	function()
		local v = POP()[1]
		if type(v) ~= 'table' then
			v = std.num(v)
			local result = {
				math.floor(v / 3600),
				math.floor(v / 60) % 60,
				math.floor(v) % 60,
			}
			local millis = math.floor(v * 1000) % 1000
			if millis ~= 0 then result[4] = millis end
			v = result
		end
		local result = ''
		for i = 1, #v do
			if i > 3 then
				result = result .. '.'
			elseif #result > 0 then
				result = result .. ':'
			end
			local val = tostring(std.num(v[i]))
			result = result .. ('0'):rep(2 - #val) .. val
		end
		PUSH(result)
	end,

	--CONVERT DATE ARRAY INTO DATE STRING
	function()
		local v = POP()[1]
		if type(v) ~= 'table' then v = { v } end
		local result = ''
		for i = #v, 1, -1 do
			if #result > 0 then result = result .. '-' end
			local val = tostring(std.num(v[i]))
			result = result .. ('0'):rep(2 - #val) .. val
		end
		PUSH(result)
	end,

	--SELECT NON-REPEATING RANDOM ELEMENTS FROM ARRAY
	function()
		local v = POP()
		local result = std.array()
		if type(v[1]) ~= 'table' then v[1] = { v[1] } end

		for i = 1, math.min(std.num(v[2]), #v[1]) do
			local index = math.random(1, #v[1])

			--To make sure that no elements repeat,
			--Remove elements from source and insert them in dest.
			table.insert(result, table.remove(v[1], index))
		end

		PUSH(result)
	end,

	--GET FIRST MATCH FROM A PATTERN ON A STRING
	function()
		local v = POP()
		PUSH(std.str(v[1]):match(std.str(v[2])))
	end,

	--SPLICE ARRAY
	function()
		local v = POP()
		local array1, index1, index2, array2 = v[1], std.num(v[2]), std.num(v[3]), v[4]
		local result = std.array()

		if type(array1) ~= 'table' then array1 = { array1 } end
		if type(array2) ~= 'table' then array2 = { array2 } end

		for i = 1, index1 - 1 do table.insert(result, array1[i]) end
		for i = 1, #array2 do table.insert(result, array2[i]) end
		for i = index2 + 1, #array1 do table.insert(result, array1[i]) end
		PUSH(result)
	end,

	--GENERATE UUID
	function()
		POP()

		local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
		local uuid = string.gsub(template, '[xy]', function(c)
			local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
			return string.format('%x', v)
		end)

		PUSH(uuid)
	end,

	--CONVERT GLOB PATTERN TO LIST OF STRINGS
	function()
		local v = POP()
		local pattern = std.str(v[1])
		local result = std.array()

		for i = 2, #v do
			if std.type(v[i]) == 'array' then
				for k = 1, #v[i] do
					local val = pattern:gsub("%*", std.str(v[i][k]))
					table.insert(result, val)
				end
			else
				local val = pattern:gsub("%*", std.str(v[i]))
				table.insert(result, val)
			end
		end

		PUSH(result)
	end,

	--SERIALIZE DATA TO XML
	function() PUSH(XML.stringify(POP()[1])) end,

	--DESERIALIZE DATA FROM XML
	function() PUSH(XML.parse(std.str(POP()[1]))) end,

	--LOGARITHM
	function()
		local v = POP()
		local base, value = v[2], std.num(v[1])
		if base ~= nil then
			base = std.num(base)
			if base <= 1 then
				error('Error: log() base must be greater than 1!')
				return
			end
		end

		PUSH(math.log(value, base))
	end,

	--NORMALIZE A VECTOR
	function()
		local v = POP()[1]
		if std.type(v) ~= 'array' then
			v = { std.num(v) }
		end
		PUSH(std.normalize(v))
	end,

	--SELECT A RANDOM ELEMENT ACCORDING TO A DISTRIBUTION
	function()
		local v = POP()
		local vector, weights = v[1], v[2]
		if std.type(vector) ~= 'array' then
			vector = { std.num(vector) }
		end
		if std.type(weights) ~= 'array' then
			weights = { std.num(weights) }
		end
		PUSH(std.random_weighted(vector, weights))
	end,

	--TRIM CHARACTERS FROM A STRING
	function()
		local v = POP()
		local text, chars = std.str(v[1]), std.str(v[2])

		if chars == nil then
			PUSH(text:match('^%s*(.-)%s*$'))
			return
		end

		-- Remove any of a list of chars
		local pattern = '^[' .. std.str(chars):gsub('(%W)', '%%%1') .. ']*(.-)[' ..
			std.str(chars):gsub('(%W)', '%%%1') .. ']*$'
		PUSH(text:match(pattern))
	end,

	mathfunc('modf'),

	--CONVERT A NUMERIC STRING FROM ANY BASE TO A NUMBER
	function()
		local v = POP()
		local str_value, base = std.str(v[1]), std.num(v[2])
		if base < 2 or base > 36 then
			error('Error: from_base() base must be between 2 and 36!')
			return
		end
		PUSH(std.from_base(str_value, base))
	end,

	--[[minify-delete]]
	--CONVERT A DATETIME OBJECT TO A UNIX TIMESTAMP
	function()
		local dt = POP()[1]
		if std.type(dt) ~= 'object' then
			PUSH(0)
			return
		end
		PUSH(os.time {
			year = dt.date and dt.date[3],
			month = dt.date and dt.date[2],
			day = dt.date and dt.date[1],
			hour = dt.time and dt.time[1],
			min = dt.time and dt.time[2],
			sec = dt.time and dt.time[3],
		})
	end,

	--CONVERT A UNIX TIMESTAMP TO A DATETIME OBJECT
	function()
		local timestamp = POP()[1]
		local datetime = std.object()
		if std.type(timestamp) ~= 'number' then
			PUSH(datetime)
			return
		end
		local dt = os.date('*t', timestamp)
		datetime.date = { dt.day, dt.month, dt.year }
		datetime.time = { dt.hour, dt.min, dt.sec }
		PUSH(datetime)
	end,

	--GET THE CURRENT EPOCH TIME
	function()
		POP()
		PUSH(os.time())
	end,

	--LIST ALL FILES THAT MATCH A GLOB PATTERN
	function()
		local pattern = std.str(POP()[1])

		local lfs = FS.rocks.lfs
		if not lfs then
			error('Error in file_glob(): Lua lfs module not installed!')
			return
		end

		PUSH(FS.glob_files(pattern))
	end,

	--CHECK IF A FILE EXISTS
	function() PUSH(FS.file_exists(std.str(POP()[1]))) end,

	--GET FILE SIZE
	function() PUSH(FS.file_size(std.str(POP()[1]))) end,

	--READ FILE CONTENTS
	function() PUSH(FS.file_read(std.str(POP()[1]))) end,

	--WRITE FILE CONTENTS
	function()
		local v = POP()
		PUSH(FS.file_write(std.str(v[1]), std.str(v[2]), false))
	end,

	--APPEND TO FILE
	function()
		local v = POP()
		PUSH(FS.file_write(std.str(v[1]), std.str(v[2]), true))
	end,

	--DELETE A FILE
	function() PUSH(FS.file_delete(std.str(POP()[1]))) end,

	--MAKE A DIRECTORY
	function()
		local v = POP()
		PUSH(FS.dir_create(std.str(v[1]), std.bool(v[2])))
	end,

	--LIST FILES IN A DIRECTORY
	function()
		local v = POP()
		PUSH(FS.dir_list(std.str(v[1])))
	end,

	--DELETE A DIRECTORY
	function()
		local v = POP()
		PUSH(FS.dir_delete(std.str(v[1]), std.bool(v[2])))
	end,

	--GET THE TYPE OF A FILESYSTEM OBJECT
	function() PUSH(FS.file_type(std.str(POP()[1]))) end,

	--STAT A FILE
	function() PUSH(FS.file_stat(std.str(POP()[1]))) end,

	--COPY A FILE
	function()
		local v = POP()
		PUSH(FS.file_copy(std.str(v[1]), std.str(v[2]), std.bool(v[3])))
	end,

	--MOVE A FILE
	function()
		local v = POP()
		PUSH(FS.file_move(std.str(v[1]), std.str(v[2]), std.bool(v[3])))
	end,

	--[[/minify-delete]]
}

--[[ INSTRUCTION LAYOUT
	instr = {
		command,
		line number,
		param1,
		param2,
	}
]]

COMMANDS = {
	--CALL
	function(line, p1, p2)
		local fn = functions[p1 + 1]
		if not fn then
			runtime_error(line, 'RUNTIME BUG: No function found for id "' .. std.str(p1) .. '"')
		else
			fn(line, p2)
		end
	end,

	--SET VARIABLE
	function(line, p1, p2)
		local v = POP()
		if v == nil then
			VARS[p1] = NULL
		else
			VARS[p1] = v
		end
	end,

	--GET VARIABLE
	function(line, p1, p2)
		if p1 == '@' then
			--List-of-params variable
			if #INSTR_STACK > 0 then
				PUSH(INSTR_STACK[#INSTR_STACK])
			else
				--If no params, then get argv
				---@diagnostic disable-next-line
				PUSH(PGM_ARGS or {})
			end
		elseif p1 == '$' then
			--List-of-commands variable
			local res = {}
			for k in pairs(BUILTIN_COMMANDS --[[@as table]]) do table.insert(res, k) end
			for k in pairs(ALLOWED_COMMANDS --[[@as table]]) do table.insert(res, k) end
			table.sort(res)
			PUSH(res)
		elseif p1 == '_VARS' then
			--List-of-vars variable
			PUSH(VARS)
		elseif p1 == '_VERSION' then
			--Version variable
			PUSH(_G['VERSION'])
		else
			local v = VARS[p1]
			if v == NULL then PUSH(nil) else PUSH(v) end
		end
	end,

	--PUSH VALUE ONTO STACK
	function(line, p1, p2) PUSH(p1) end,

	--POP VALUE FROM STACK
	function(line, p1, p2) POP() end,

	--RUN COMMAND
	function(line, p1, p2)
		local command_array = POP()
		local cmd_array = {}
		for i = 1, #command_array do
			if std.type(command_array[i]) == 'array' then
				for k = 1, #command_array[i] do
					table.insert(cmd_array, std.str(command_array[i][k]))
				end
			elseif std.type(command_array[i]) == 'object' then
				for key, value in pairs(command_array[i]) do
					table.insert(cmd_array, std.str(key))
					table.insert(cmd_array, std.str(value))
				end
			else
				table.insert(cmd_array, std.str(command_array[i]))
			end
		end
		command_array = cmd_array
		local cmd_name = std.str(command_array[1])

		if not ALLOWED_COMMANDS[cmd_name] and not BUILTIN_COMMANDS[cmd_name] then
			--If command doesn't exist, try to help user by guessing the closest match (but still throw an error)
			local msg = 'Unknown command "' .. cmd_name .. '"'
			local guess = closest_word(cmd_name, ALLOWED_COMMANDS, 4)
			if guess == nil or guess == '' then
				guess = closest_word(cmd_name, BUILTIN_COMMANDS, 4)
			end

			if guess ~= nil and guess ~= '' then
				msg = msg .. ' (did you mean "' .. guess .. '"?)'
			end
			runtime_error(line, msg)
		end

		if not ALLOWED_COMMANDS[cmd_name] then
			if cmd_name == 'sleep' then
				local amt = math.max(0.02, std.num(command_array[2])) - 0.02
				output(amt, 4)
			elseif cmd_name == 'time' then
				output(nil, 5)
			elseif cmd_name == 'systime' then
				output(1, 6)
			elseif cmd_name == 'sysdate' then
				output(2, 6)
			elseif cmd_name == 'print' --[[minify-delete]] or cmd_name == 'stdin' or cmd_name == 'stdout' or cmd_name == 'stderr' or cmd_name == 'clear' --[[/minify-delete]] then
				table.remove(command_array, 1)
				local msg = std.join(command_array, ' ')
				output_array({ cmd_name, msg }, 7)
			elseif cmd_name == 'error' then
				table.remove(command_array, 1)
				local msg = std.join(command_array, ' ')

				if #EXCEPT_STACK > 0 then
					--if exception is caught, unroll the stack and return to the catch block

					local err = std.object()
					err.message = msg
					err.stack = { line }

					--Unroll program stack
					local catch = table.remove(EXCEPT_STACK)
					while #STACK > catch.stack do
						table.remove(STACK)
					end

					--Unroll call stack
					while #INSTR_STACK > catch.instr_stack do
						table.remove(INSTR_STACK) --Remove any subroutine parameters
						table.remove(INSTR_STACK) --Remove stack size value
						local instr_id = table.remove(INSTR_STACK)
						table.insert(err.stack, 1, INSTRUCTIONS[instr_id][2])
					end
					CURRENT_INSTRUCTION = catch.instr

					err.line = table.remove(err.stack, 1)

					PUSH(err)
					return false --Don't output the error
				else
					--If exception is not caught, end the program immediately and output the error
					CURRENT_INSTRUCTION = #INSTRUCTIONS + 1

					---@diagnostic disable-next-line
					if FILE and #FILE > 0 then
						msg = '["' .. FILE .. '": ' .. line .. '] ' .. msg
					else
						msg = '[line ' .. line .. '] ' .. msg
					end
					output_array({ "error", 'ERROR: ' .. msg .. '\nError not caught, program terminated.' }, 7)
				end

				--[[minify-delete]]
			elseif cmd_name == '!' or cmd_name == '?' or cmd_name == '?!' or cmd_name == '=' then
				table.remove(command_array, 1)
				--Quote and escape all params, this will be run thru shell
				local text = ''
				for i = 1, #cmd_array do
					local cmd_text = cmd_array[i]
					if cmd_text:sub(1, #_G['RAW_SH_TEXT_SENTINEL']) == _G['RAW_SH_TEXT_SENTINEL'] then
						cmd_text = cmd_text:sub(#_G['RAW_SH_TEXT_SENTINEL'] + 1)
						text = text .. cmd_text .. ' '
					else
						cmd_text = cmd_text:gsub('\\', '\\\\'):gsub(
							'"', '\\"'):gsub('%$', '\\$'):gsub('`', '\\`'):gsub('!', '\\!')
						--Escape strings correctly in powershell
						if _G['WINDOWS'] then cmd_text = cmd_text:gsub('\\"', '`"') end
						text = text .. '"' .. cmd_text .. '" '
					end
				end
				output_array({ cmd_name, text }, 9)
				--[[/minify-delete]]
			elseif cmd_name == '.' then
				--No-op (results are calculated but discarded)
			else
				runtime_error(line, 'RUNTIME BUG: No logic implemented for built-in command "' .. command_array[1] .. '"')
			end
		else
			output_array(command_array, 2)
		end
		return true --Suppress regular "continue" output
	end,

	--PUSH LAST COMMAND RESULT TO THE STACK
	function(line, p1, p2)
		PUSH(LAST_CMD_RESULT)
	end,

	--PUSH THE CURRENT INSTRUCTION INDEX TO THE STACK
	function(line, p1, p2)
		table.insert(INSTR_STACK, CURRENT_INSTRUCTION + 1)
		table.insert(INSTR_STACK, #STACK - 1)          --Keep track of how big the stack SHOULD be when returning
		table.insert(INSTR_STACK, STACK[#STACK - (p1 or 0)]) --Append any subroutine parameters (with offset, if any)
	end,

	--POP THE NEW INSTRUCTION INDEX FROM THE STACK (GOTO THAT INDEX)
	function(line, p1, p2)
		table.remove(INSTR_STACK) --Remove any subroutine parameters
		local new_stack_size = table.remove(INSTR_STACK)
		CURRENT_INSTRUCTION = table.remove(INSTR_STACK)

		if not p1 then
			--Put any subroutine return value in the "command return value" slot
			V5 = table.remove(STACK)

			--Shrink stack back down to how big it should be
			while new_stack_size < #STACK do
				table.remove(STACK)
			end
		end
	end,

	--COPY THE NTH STACK ELEMENT ONTO THE STACK AGAIN (BACKWARDS FROM TOP)
	function(line, p1, p2)
		PUSH(STACK[#STACK - p1])
	end,

	--DELETE VARIABLE
	function(line, p1, p2)
		VARS[p1] = nil
	end,

	--SWAP THE TOP 2 ELEMENTS ON THE STACK
	function(line, p1, p2)
		local v1 = STACK[#STACK]
		local v2 = STACK[#STACK - 1]
		STACK[#STACK - 1] = v1
		STACK[#STACK] = v2
	end,

	--POP STACK UNTIL AND INCLUDING NULL
	function(line, p1, p2)
		local keep = {}
		if p1 then
			--Keep the N top elements
			for i = 1, p1 do
				if STACK[#STACK] == NULL then break end
				table.insert(keep, POP())
			end
		end
		while POP() ~= nil do end
		if p1 then
			--Re-push the N top elements
			for i = #keep, 1, -1 do
				PUSH(keep[i])
			end
		end
	end,

	--GET VALUE FROM CACHE IF IT EXISTS, ELSE JUMP
	function(line, p1, p2)
		local params = {}
		if #INSTR_STACK > 0 then params = INSTR_STACK[#INSTR_STACK] end

		--If cache value exists, place it in the "command return" slot.
		if MEMOIZE_CACHE[p1] then
			local serialized = json.stringify(params)
			if MEMOIZE_CACHE[p1][serialized] ~= nil then
				PUSH(MEMOIZE_CACHE[p1][serialized])
				return
			end
		end

		--if cache doesn't exist, jump.
		CURRENT_INSTRUCTION = p2
	end,

	--SET CACHE FROM RETURN VALUE
	function(line, p1, p2)
		local params = {}
		if #INSTR_STACK > 0 then params = INSTR_STACK[#INSTR_STACK] end

		if not MEMOIZE_CACHE[p1] then MEMOIZE_CACHE[p1] = {} end
		MEMOIZE_CACHE[p1][json.stringify(params)] = V5
		PUSH(V5)
	end,

	--DELETE VALUE FROM MEMOIZATION CACHE
	function(line, p1, p2)
		MEMOIZE_CACHE[p1] = nil
	end,

	--PUSH CATCH RETURN LOCATION ONTO EXCEPTION STACK
	function(line, p1, p2)
		table.insert(EXCEPT_STACK, {
			instr = p1,
			stack = #STACK,
			instr_stack = #INSTR_STACK,
		})
	end,
}
