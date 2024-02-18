--TEMP: read bytecode from stdin. only for testing
-- INSTRUCTIONS = {}
-- CURRENT_INSTRUCTION = 0
-- LAST_CMD_RESULT = nil
-- RANDOM_SEED = 0 --Change this later
MAX_ITER = 100 --Max number of instructions to run before pausing execution (performance reasons mostly)

NULL = {}
-- STACK = {}
-- VARS = {}

function runtime_error(line, msg)
	if msg:sub(1, 12) == 'RUNTIME BUG' then
		msg = msg .. '\nTHIS IS A BUG IN THE PAISLEY COMPILER, PLEASE REPORT IT!'
	end

	if FILE ~= nil and FILE ~= '' then
		print(FILE..': '..line..': '..msg)
	else
		print(line..': '..msg)
	end
	error('ERROR in user-supplied Paisley script.')
end

local function POP()
	local val = STACK[#STACK]
	table.remove(STACK)
	if val == NULL then return nil end
	return val
end

local function PUSH(value)
	if value == nil then
		table.insert(STACK, NULL)
	elseif type(value) == 'table' then
		--DEEP COPY tables into the stack. It's slower, but it prevents data from randomly mutating!
		local result, i = {}
		for i = 1, #value do
			table.insert(result, value[i])
		end
		table.insert(STACK, result)
	else
		table.insert(STACK, value)
	end
end

local function mathfunc(funcname)
	return function(line)
		local v, p, i = POP(), {}
		for i = 1, #v do
			table.insert(p, std.num(v[i]))
		end

		local u = table.unpack
		if not u then u = unpack end

		PUSH(math[funcname](u(v)))
	end
end

local function number_op(v1, v2, operator)
	if type(v1) == 'table' or type(v2) == 'table' then
		if type(v1) ~= 'table' then v1 = {v1} end
		if type(v2) ~= 'table' then v2 = {v2} end

		local result, i = {}
		for i = 1, math.min(#v1, #v2) do
			table.insert(result, operator(std.num(v1[i]), std.num(v2[i])))
		end
		return result
	else
		return operator(std.num(v1), std.num(v2))
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
		local array, i = POP()
		if type(array) ~= 'table' then
			PUSH(array)
			return
		end

		for i = 1, #array do
			local val = array[#array - i + 1]
			PUSH(val)
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
		local array, i = {}
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
	function()
		local v1, v2 = POP(), POP()
		local result = number_op(v2, v1, function(a, b) return a + b end)
		PUSH(result)
	end,

	--SUB
	function()
		local v1, v2 = POP(), POP()
		local result = number_op(v2, v1, function(a, b) return a - b end)
		PUSH(result)
	end,

	--MUL
	function()
		local v1, v2 = POP(), POP()
		local result = number_op(v2, v1, function(a, b) return a * b end)
		PUSH(result)
	end,

	--DIV
	function()
		local v1, v2 = POP(), POP()
		local result = number_op(v2, v1, function(a, b) return a / b end)
		PUSH(result)
	end,

	--REM
	function()
		local v1, v2 = POP(), POP()
		local result = number_op(v2, v1, function(a, b) return a % b end)
		PUSH(result)
	end,

	--LENGTH
	function()
		local val = POP()
		if type(val) == 'table' then PUSH(#val) else PUSH(#std.str(val)) end
	end,

	--ARRAY INDEX
	function()
		local index, data, i = POP(), POP()
		if type(data) ~= 'table' then data = std.split(std.str(data), '') end
		if type(index) ~= 'table' then
			PUSH(data[std.num(index)])
		else
			local result = {}
			for i = 1, #index do
				table.insert(result, data[std.num(index[i])])
			end
			PUSH(result)
		end
	end,

	--ARRAYSLICE
	function(line)
		local stop, start, i = std.num(POP()), std.num(POP())
		local array = {}

		--For performance, limit how big slices can be.
		local max_arr_sz = 65535
		if stop - start > max_arr_sz then
			print('WARNING: line '..line..': Attempt to create an array of '..(stop - start)..' elements (max is '..max_arr_sz..')')
			stop = start + 65535
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
			result = std.str(POP())..result
			param = param - 1
		end
		PUSH(result)
	end,

	--BOOLEAN AND
	function() PUSH(std.bool(POP()) and std.bool(POP())) end,

	--BOOLEAN OR
	function() PUSH(std.bool(POP()) or std.bool(POP())) end,

	--BOOLEAN XOR
	function()
		local a, b = std.bool(POP()), std.bool(POP())
		PUSH((a or b) and not (a and b))
	end,

	--IN ARRAY/STRING
	function()
		local data, val = POP(), POP()
		local result = false
		if type(data) == 'table' then
			local i
			for i = 1, #data do
				if data[i] == val then
					result = true
					break
				end
			end
		else
			result = std.contains(std.str(data), val)
		end
		PUSH(result)
	end,

	--STRING LIKE PATTERN
	function()
		local str, pattn = std.str(POP()), std.str(POP())
		PUSH(str:match(pattn) ~= nil)
	end,

	--EQUAL
	function() PUSH(POP() == POP()) end,

	--NOT EQUAL
	function() PUSH(POP() ~= POP()) end,

	--GREATER THAN
	function() PUSH(POP() < POP()) end,

	--GREATER THAN OR EQUAL
	function() PUSH(POP() <= POP()) end,

	--LESS THAN
	function() PUSH(POP() > POP()) end,

	--LESS THAN OR EQUAL
	function() PUSH(POP() >= POP()) end,

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

		if t1 ~= 'table' and t2 == 'table' then b = b[1]
		elseif t1 == 'table' and t2 ~= 'table' then a = a[1]
		end

		if t1 == 'table' then
			local total, i = 0
			for i = 1, math.min(#a, #b) do
				local p = a[i] - b[i]
				total = total + p*p
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
		local v, total, i = POP(), 0
		for i = 1, #v do
			if type(v[i]) == 'table' then
				local k
				for k = 1, #v[i] do total = total + std.num(v[i][k]) end
			else
				total = total + std.num(v[i])
			end
		end
		PUSH(total)
	end,

	--MULT
	function()
		local v, total, i = POP(), 1
		for i = 1, #v do
			if type(v[i]) == 'table' then
				local k
				for k = 1, #v[i] do total = total * std.num(v[i][k]) end
			else
				total = total * std.num(v[i])
			end
		end
		PUSH(total)
	end,

	--MORE MATH FUNCTIONS
	mathfunc('pow'),

	--MIN of arbitrary number of arguments
	function()
		local v, target = POP()

		for i = 1, #v do
			if type(v[i]) == 'table' then
				for k = 1, #v[i] do
					if target then target = math.min(target, std.num(v[i][k])) else target = std.num(v[i][k]) end
				end
			else
				if target then target = math.min(target, std.num(v[i][k])) else target = std.num(v[i][k]) end
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
				if target then target = math.max(target, std.num(v[i][k])) else target = std.num(v[i][k]) end
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
	function() PUSH(std.bool(POP()[1])) end,

	--NUM
	function() PUSH(std.num(POP()[1])) end,

	--STR
	function() PUSH(std.str(POP()[1])) end,

	--ARRAY
	function() end, --Due to a quirk of the compiler, don't have to do anything.

	--MORE MATH FUNCTIONS
	mathfunc('floor'),
	mathfunc('ceil'),
	mathfunc('round'),
	mathfunc('abs'),

	--ARRAY APPEND
	function()
		local v = POP()
		if type(v[1]) == 'table' then
			table.insert(v[1], v[2])
			PUSH(v[1])
		else
			PUSH({v[1], v[2]})
		end
	end,

	--INDEX
	function()
		local v = POP()
		local res
		if type(v[1]) == 'table' then
			res = std.arrfind(v[1], v[2])
		else
			res = std.strfind(std.str(v[1]), std.str(v[2]))
		end
		PUSH(res)
	end,

	--LOWERCASE
	function()
		PUSH( std.str(POP()):lower() )
	end,

	--UPPERCASE
	function()
		PUSH( std.str(POP()):upper() )
	end,

	--CAMEL CASE
	function()
		local v = std.str(POP())
		PUSH(v:gsub('(%l)(%w*)', function(x,y) return x:upper()..y end))
	end,

	--STRING REPLACE
	function()
		local v = POP()
		PUSH( std.join(std.split(std.str(v[3]), std.str(v[2])), std.str(v[1])) )
	end,

	--JSON_ENCODE
	function(line)
		local v = POP()
		local res, err = json.stringify(v[1], nil, true)
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
		PUSH( std.b64_encode(std.str(POP()[1])) )
	end,

	--BASE64_DECODE
	function()
		PUSH( std.b64_decode(std.str(POP()[1])) )
	end,

	--LEFT PAD STRING
	function()
		local v = POP()
		local text = std.str(v[1])
		local character = std.str(v[2]):sub(1,1)
		local width = std.num(v[3])

		PUSH( character:rep(width - #text) .. text )
	end,

	--RIGHT PAD STRING
	function()
		local v = POP()
		local text = std.str(v[1])
		local character = std.str(v[2]):sub(1,1)
		local width = std.num(v[3])

		PUSH( text .. character:rep(width - #text) )
	end,

	--CONVERT NUMBER TO HEX
	function()
		PUSH( string.format('%x', std.num(POP()[1])) )
	end,

	--FILTER STRING CHARS BASED ON PATTERN
	function()
		local v = POP()
		PUSH(std.filter(std.str(v[1]), std.str(v[2])))
	end,

	--GET NEXT PATTERN MATCH
	function()
		local v = POP()
		local m = std.str(v[1]):match(std.str(v[2]))
		if m then PUSH(m) else PUSH('') end
	end,

	--SPLIT A NUMBER INTO CLOCK TIME
	function()
		local v = std.num(POP()[1])
		PUSH({
			math.floor(v / 3600),
			math.floor(v / 60) % 60,
			math.floor(v) % 60,
			math.floor(v * 1000) % 1000,
		})
	end,

	--REVERSE ARRAY OR STRING
	function()
		local v = POP()[1]
		if type(v) == 'string' then
			PUSH(v:reverse())
			return
		elseif type(v) ~= 'table' then
			PUSH({v})
			return
		end

		local result, i = {}
		for i = #v, 1, -1 do
			table.insert(result, v[i])
		end

		PUSH(result)
	end,
	--SORT ARRAY
	function()
		local v = POP()[1]
		if type(v) ~= 'table' then
			PUSH({v})
			return
		end

		table.sort(v)
		PUSH(v)
	end,

	--BYTES FROM NUMBER
	function()
		local v = POP()
		local result, i = {}
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
			local result, i = 0
			for i = 1, #v[1] do
				result = result * 256 + v[1][i]
			end
			PUSH(result)
		end
	end,

	--MERGE TWO ARRAYS
	function()
		local v, i = POP()
		if type(v[1]) ~= 'table' then v[1] = {v[1]} end
		if type(v[2]) ~= 'table' then v[2] = {v[2]} end

		for i = 1, #v[2] do
			table.insert(v[1], v[2][i])
		end
		PUSH(v[1])
	end,

	--UPDATE ELEMENT IN ARRAY
	function()
		local v = POP()
		if type(v[1]) ~= 'table' then v[1] = {v[1]} end
		local n = std.num(v[2])

		--If index is negative, update starting at the end
		if n < 0 then n = #v[1] + n + 1 end

		if n > 0 then
			--Update the value if non-negative (this can also increase array lengths)
			v[1][n] = v[3]
		else
			--Insert at beginning if index is less than 1
			table.insert(v[1], 1, v[3])
		end

		PUSH(v[1])
	end,

	--INSERT ELEMENT IN ARRAY
	function()
		local v = POP()
		if type(v[1]) ~= 'table' then v[1] = {v[1]} end
		local n = std.num(v[2])

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
		PUSH(v[1])
	end,

	--DELETE ELEMENT FROM ARRAY
	function()
		local v = POP()
		if type(v[1]) ~= 'table' then v[1] = {v[1]} end
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
		if type(v[1]) ~= 'table' then PUSH(v[1])
		else
			PUSH(v[1][math.random(0, #v[1])])
		end
	end,

	--GENERATE SHA256 HASH OF A STRING
	function()
		PUSH( std.hash(std.str( POP()[1] )) )
	end,
}

--[[ INSTRUCTION LAYOUT
	instr = {
		command,
		line number,
		param1,
		param2,
	}
]]

commands = {
	--CALL
	[0] = function(line, p1, p2) functions[p1+1](line, p2) end,

	--SET VARIABLE
	[2] = function(line, p1, p2)
		local v = POP()
		if v == nil then
			VARS[p1] = NULL
		else
			VARS[p1] = v
		end
	end,

	--GET VARIABLE
	[3] = function(line, p1, p2)
		if p1 == '@' then
			local res, k = {}
			for k in pairs(VARS) do
				if VARS[k] ~= nil then table.insert(res, k) end
			end
			table.sort(res)
			PUSH(res)
		elseif p1 == '$' then
			local res, k = {}
			for k in pairs(BUILTIN_COMMANDS) do table.insert(res, k) end
			for k in pairs(ALLOWED_COMMANDS) do table.insert(res, k) end
			table.sort(res)
			PUSH(res)
		else
			PUSH(VARS[p1])
		end
	end,

	--PUSH VALUE ONTO STACK
	[4] = function(line, p1, p2)
		PUSH(p1)
	end,

	--POP VALUE FROM STACK
	[5] = function(line, p1, p2)
		POP()
	end,

	--RUN COMMAND
	[6] = function(line, p1, p2)
		local command_array = POP()
		local cmd_array, i = {}
		for i = 1, #command_array do
			if type(command_array[i]) == 'table' then
				local k
				for k = 1, #command_array[i] do
					table.insert(cmd_array, std.str(command_array[i][k]))
				end
			else
				table.insert(cmd_array, std.str(command_array[i]))
			end
		end
		command_array = cmd_array
		local cmd_name = std.str(command_array[1])

		if not ALLOWED_COMMANDS[cmd_name] and not BUILTIN_COMMANDS[cmd_name] then
			--If command doesn't exist, try to help user by guessing the closest match (but still throw an error)
			msg = 'Unknown command "'..cmd_name..'"'
			local guess = closest_word(cmd_name, ALLOWED_COMMANDS, 4)
			if guess == nil or guess == '' then
				guess = closest_word(cmd_name, BUILTIN_COMMANDS, 4)
			end

			if guess ~= nil and guess ~= '' then
				msg = msg .. ' (did you mean "'..guess..'"?)'
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
			elseif cmd_name == 'print' then
				table.remove(command_array, 1)
				local msg = std.join(command_array, ' ')
				output_array({"print", msg}, 7)
			elseif cmd_name == 'error' then
				table.remove(command_array, 1)
				local msg = line..': '..std.join(command_array, ' ')
				if file then msg = file..': '..msg end
				output_array({"error", msg}, 7)
			else
				runtime_error(line, 'RUNTIME BUG: No logic implemented for built-in command "'..command_array[1]..'"')
			end
		else
			output_array(command_array, 2)
		end
		return true --Suppress regular "continue" output
	end,

	--PUSH LAST COMMAND RESULT TO THE STACK
	[7] = function(line, p1, p2)
		PUSH(LAST_CMD_RESULT)
	end,

	--PUSH THE CURRENT INSTRUCTION INDEX TO THE STACK
	[8] = function(line, p1, p2)
		table.insert(INSTR_STACK, CURRENT_INSTRUCTION + 1)
		table.insert(INSTR_STACK, #STACK) --Keep track of how big the stack SHOULD be when returning
	end,

	--POP THE NEW INSTRUCTION INDEX FROM THE STACK (GOTO THAT INDEX)
	[9] = function(line, p1, p2)
		local new_stack_size = table.remove(INSTR_STACK)
		CURRENT_INSTRUCTION = table.remove(INSTR_STACK)

		--Shrink stack back down to how big it should be
		while new_stack_size < #STACK do
			table.remove(STACK)
		end
	end,

	--COPY THE NTH STACK ELEMENT ONTO THE STACK AGAIN (BACKWARDS FROM TOP)
	[10] = function(line, p1, p2)
		PUSH(STACK[#STACK - p1])
		-- error('AGGA')
	end,

	--DELETE VARIABLE
	[11] = function(line, p1, p2)
		VARS[p1] = nil
	end,

	--SWAP THE TOP 2 ELEMENTS ON THE STACK
	[12] = function(line, p1, p2)
		v1 = STACK[#STACK]
		v2 = STACK[#STACK-1]
		STACK[#STACK-1] = v1
		STACK[#STACK] = v2
	end,
}
