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
local fs = require 'src.util.filesystem'
--[[/minify-delete]]

local json = require "src.shared.json"

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

local functions = {
	--JUMP
	require 'src.runtime.functions.jump',
	--JUMP IF NIL
	require 'src.runtime.functions.jumpifnil',
	--JUMP IF FALSEY
	require 'src.runtime.functions.jumpiffalse',
	--EXPLODE: only used in for loops
	require 'src.runtime.functions.explode',
	--IMPLODE
	require 'src.runtime.functions.implode',
	--SUPERIMPLODE
	require 'src.runtime.functions.superimplode',
	--ADD
	require 'src.runtime.functions.add',
	--SUB
	require 'src.runtime.functions.sub',
	--MUL
	require 'src.runtime.functions.mul',
	--DIV
	require 'src.runtime.functions.div',
	--REM
	require 'src.runtime.functions.rem',
	--LENGTH
	require 'src.runtime.functions.length',
	--ARRAY INDEX
	require 'src.runtime.functions.arrayindex',
	--ARRAYSLICE
	require 'src.runtime.functions.arrayslice',
	--CONCAT
	require 'src.runtime.functions.concat',
	--BOOLEAN AND
	require 'src.runtime.functions.booland',
	--BOOLEAN OR
	require 'src.runtime.functions.boolor',
	--BOOLEAN XOR
	require 'src.runtime.functions.boolxor',
	--IN ARRAY/STRING
	require 'src.runtime.functions.inarray',
	--STRING LIKE PATTERN
	require 'src.runtime.functions.strlike',

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
	require 'src.runtime.functions.sin',
	require 'src.runtime.functions.cos',
	require 'src.runtime.functions.tan',
	require 'src.runtime.functions.asin',
	require 'src.runtime.functions.acos',
	require 'src.runtime.functions.atan',
	require 'src.runtime.functions.atan2',
	require 'src.runtime.functions.sqrt',

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
	require 'src.runtime.functions.pow',

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
	require 'src.runtime.functions.floor',
	require 'src.runtime.functions.ceil',

	--ROUND
	function() PUSH(math.floor(std.num(POP()[1]) + 0.5)) end,

	require 'src.runtime.functions.abs',

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

		local res, err = json.stringify(v[1], indent)
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
		local object, indices, value = v[1], v[2], v[3]

		PUSH(std.update_element(object, indices, value))
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
		local ratio, a, b = std.num(v[1]), v[2], v[3]
		if std.type(a) == 'array' or std.type(b) == 'array' then
			if type(a) ~= 'table' then a = { a } end
			if type(b) ~= 'table' then b = { b } end

			local result = {}
			for i = 1, math.min(#a, #b) do
				local start = std.num(a[i])
				local stop = std.num(b[i])
				result[i] = start + ratio * (stop - start)
			end
			PUSH(result)
			return
		end
		a = std.num(a)
		b = std.num(b)
		PUSH(a + ratio * (b - a))
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
	require 'src.runtime.functions.union',
	--INTERSECTION OF TWO SETS
	require 'src.runtime.functions.intersection',
	--DIFFERENCE OF TWO SETS
	require 'src.runtime.functions.difference',
	--SYMMETRIC DIFFERENCE OF TWO SETS
	require 'src.runtime.functions.symmetric_difference',
	--CHECK IF TWO SETS ARE DISJOINT
	require 'src.runtime.functions.is_disjoint',
	--CHECK IF ONE SET IS A SUBSET OF ANOTHER
	require 'src.runtime.functions.is_subset',
	--CHECK IF ONE SET IS A SUPERSET OF ANOTHER
	require 'src.runtime.functions.is_superset',

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
		local function flatten(array, depth)
			local result = std.array()
			for i = 1, #array do
				if depth > 0 and type(array[i]) == 'table' then
					local flat = flatten(array[i], depth - 1)
					for k = 1, #flat do table.insert(result, flat[k]) end
				else
					table.insert(result, array[i])
				end
			end
			return result
		end

		local v = POP()
		if type(v[1]) ~= 'table' then
			PUSH({ v[1] })
			return
		end

		PUSH(flatten(v[1], v[2] and std.num(v[2]) or math.maxinteger))
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
	require 'src.runtime.functions.sinh',
	require 'src.runtime.functions.cosh',
	require 'src.runtime.functions.tanh',

	--SIGN OF A NUMBER
	function() PUSH(std.sign(std.num(POP()[1]))) end,

	--CHAR TO ASCII
	function() PUSH(string.byte(std.str(POP()[1]))) end,

	--ASCII TO CHAR
	function()
		local num = math.floor(std.num(POP()[1]))

		local nans = {
			['nan'] = true,
			['inf'] = true,
			['-inf'] = true,
		}

		if nans[tostring(num)] then num = 0 end
		PUSH(string.char(num % 256))
	end,

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

	require 'src.runtime.functions.modf',

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

	--CHUNK AN ARRAY INTO SUB-ARRAYS OF A GIVEN SIZE
	function()
		local v = POP()
		local array, size = v[1], std.num(v[2])
		if std.type(array) ~= 'array' then
			print('WARNING: chunk() first argument is not an array! Coercing to an empty array.')
			array = {}
		end

		PUSH(std.chunk(array, size))
	end,

	--GET ENVIRONMENT VARIABLE
	function()
		--Environment variables are always null in the plasma build.

		--[[minify-delete]]
		if true then
			PUSH(os.getenv(std.str(POP()[1])))
		else
			--[[/minify-delete]]
			PUSH(nil)
			--[[minify-delete]]
		end
		--[[/minify-delete]]
	end,

	--CONVERT A TIME ARRAY INTO A TIMESTAMP
	function()
		local v = POP()[1]
		if type(v) ~= 'table' then
			PUSH(0)
			return
		end
		PUSH((v[1] or 0) * 3600 + (v[2] or 0) * 60 + (v[3] or 0) + (v[4] or 0) / 1000)
	end,

	require 'src.runtime.functions.fmod',

	--CHECK IF AN ARRAY IS SORTED
	function()
		local array = POP()[1]

		if std.type(array) ~= 'array' then
			PUSH(false)
			return
		end

		local last_element = array[1]
		for i = 2, #array do
			if last_element > array[i] then
				PUSH(false)
				return
			end
			last_element = array[i]
		end
		PUSH(true)
	end,

	--BITWISE AND
	function() PUSH(std.bitwise['and'](std.num(POP()), std.num(POP()))) end,

	--BITWISE OR
	function() PUSH(std.bitwise['or'](std.num(POP()), std.num(POP()))) end,

	--BITWISE XOR
	function() PUSH(std.bitwise['xor'](std.num(POP()), std.num(POP()))) end,

	--BITWISE NOT
	function() PUSH(std.bitwise['not'](std.num(POP()))) end,

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

		local lfs = fs.rocks.lfs
		if not lfs then
			error('Error in file_glob(): Lua lfs module not installed!')
			return
		end

		PUSH(fs.glob_files(pattern))
	end,

	--CHECK IF A FILE EXISTS
	function() PUSH(fs.file_exists(std.str(POP()[1]))) end,

	--GET FILE SIZE
	function() PUSH(fs.file_size(std.str(POP()[1]))) end,

	--READ FILE CONTENTS
	function() PUSH(fs.file_read(std.str(POP()[1]))) end,

	--WRITE FILE CONTENTS
	function()
		local v = POP()
		PUSH(fs.file_write(std.str(v[1]), std.str(v[2]), false))
	end,

	--APPEND TO FILE
	function()
		local v = POP()
		PUSH(fs.file_write(std.str(v[1]), std.str(v[2]), true))
	end,

	--DELETE A FILE
	function() PUSH(fs.file_delete(std.str(POP()[1]))) end,

	--MAKE A DIRECTORY
	function()
		local v = POP()
		PUSH(fs.dir_create(std.str(v[1]), std.bool(v[2])))
	end,

	--LIST FILES IN A DIRECTORY
	function()
		local v = POP()
		PUSH(fs.dir_list(std.str(v[1])))
	end,

	--DELETE A DIRECTORY
	function()
		local v = POP()
		PUSH(fs.dir_delete(std.str(v[1]), std.bool(v[2])))
	end,

	--GET THE TYPE OF A FILESYSTEM OBJECT
	function() PUSH(fs.file_type(std.str(POP()[1]))) end,

	--STAT A FILE
	function() PUSH(fs.file_stat(std.str(POP()[1]))) end,

	--COPY A FILE
	function()
		local v = POP()
		PUSH(fs.file_copy(std.str(v[1]), std.str(v[2]), std.bool(v[3])))
	end,

	--MOVE A FILE
	function()
		local v = POP()
		PUSH(fs.file_move(std.str(v[1]), std.str(v[2]), std.bool(v[3])))
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

local vm = {
	functions = functions,
	runtime_error = runtime_error,
	pop = POP,
	push = PUSH,
}

COMMANDS = {
	--CALL FUNCTION
	require 'src.runtime.actions.call',
	--SET VARIABLE
	require 'src.runtime.actions.set',
	--GET VARIABLE
	require 'src.runtime.actions.get',
	--PUSH VALUE ONTO STACK
	require 'src.runtime.actions.push',
	--POP VALUE FROM STACK
	require 'src.runtime.actions.pop',
	--RUN COMMAND
	require 'src.runtime.actions.run_command',
	--PUSH LAST COMMAND RESULT TO THE STACK
	require 'src.runtime.actions.push_cmd_result',
	--PUSH THE CURRENT INSTRUCTION INDEX TO THE STACK
	require 'src.runtime.actions.push_index',
	--POP THE NEW INSTRUCTION INDEX FROM THE STACK (GOTO THAT INDEX)
	require 'src.runtime.actions.pop_goto_index',
	--COPY THE NTH STACK ELEMENT ONTO THE STACK AGAIN (BACKWARDS FROM TOP)
	require 'src.runtime.actions.copy',
	--DELETE VARIABLE
	require 'src.runtime.actions.delete_var',
	--SWAP THE TOP 2 ELEMENTS ON THE STACK
	require 'src.runtime.actions.swap',
	--POP STACK UNTIL AND INCLUDING NULL
	require 'src.runtime.actions.pop_until_null',
	--GET VALUE FROM CACHE IF IT EXISTS, ELSE JUMP
	require 'src.runtime.actions.get_cache_else_jump',
	--SET CACHE FROM RETURN VALUE
	require 'src.runtime.actions.set_cache',
	--DELETE VALUE FROM MEMOIZATION CACHE
	require 'src.runtime.actions.delete_cache',
	--PUSH CATCH RETURN LOCATION ONTO EXCEPTION STACK
	require 'src.runtime.actions.push_catch_loc',
	--INSERT VALUE INTO VARIABLE
	require 'src.runtime.actions.variable_insert',
	--DESTRUCTURE VALUE INTO A LIST OF VARIABLES
	require 'src.runtime.actions.destructure',
}

return vm
