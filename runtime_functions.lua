--TEMP: read bytecode from stdin. only for testing
-- INSTRUCTIONS = {}
-- CURRENT_INSTRUCTION = 0
-- LAST_CMD_RESULT = nil
-- RANDOM_SEED = 0 --Change this later
MAX_ITER = 30 --Max number of instructions to run before pausing execution (performance reasons mostly)

-- NULL = {}
-- STACK = {}
-- VARS = {}

local function POP()
	local val = STACK[#STACK]
	table.remove(STACK)
	if val == NULL then return nil end
	return val
end

local function PUSH(value)
	if value == nil then
		table.insert(STACK, NULL)
	else
		table.insert(STACK, value)
	end
end

local function mathfunc(funcname)
	return function(line)
		local v, p, i = POP(), {}
		for i = 1, #v do
			table.insert(p, std.num(p[i]))
		end

		PUSH(math[funcname](table.unpack(v)))
	end
end

local functions = {
	--JUMP
	function(line, param)
		CURRENT_INSTRUCTION = param
	end,

	--JUMP IF NIL
	function(line, param)
		if STACK[#STACK] == NULL then CURRENT_INSTRUCTION = param end
	end,

	--JUMP IF FALSEY
	function(line, param)
		if std.bool(STACK[#STACK]) == false then CURRENT_INSTRUCTION = param end
	end,

	--EXPLODE
	function(line, param)
		local array, i = POP()
		for i = 1, #array do PUSH(array[i]) end
	end,

	--IMPLODE
	function(line, param)
		local array, i = {}
		for i = 1, param do
			table.insert(array, POP())
		end
		PUSH(array)
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
		PUSH(array)
	end,

	--ADD
	function() PUSH(std.num(POP()) + std.num(POP())) end,

	--SUB
	function() PUSH(std.num(POP()) - std.num(POP())) end,

	--MUL
	function() PUSH(std.num(POP()) * std.num(POP())) end,

	--DIV
	function() PUSH(std.num(POP()) / std.num(POP())) end,

	--REM
	function() PUSH(std.num(POP()) % std.num(POP())) end,

	--LENGTH
	function()
		local val = POP()
		if type(val) == 'table' then PUSH(#VAL) else PUSH(#std.str(val)) end
	end,

	--INDEX
	function()
		local index, data, i = POP(), POP()
		if type(data) ~= 'table' then data = std.split(std.str(data), '') end
		if type(index) ~= 'table' then index = {index} end

		local result = {}
		for i = 1, index do
			table.insert(result, data[std.num(index[i])])
		end
		PUSH(result)
	end,

	--ARRAYSLICE
	function()
		local start, stop, i = std.num(POP()), std.num(POP())
		local array = {}
		for i = start, stop do
			table.insert(array, i)
		end
		PUSH(array)
	end,

	--CONCAT
	function() PUSH(std.str(POP()) .. std.str(POP())) end,

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
	function() PUSH(POP() > POP()) end,

	--GREATER THAN OR EQUAL
	function() PUSH(POP() >= POP()) end,

	--LESS THAN
	function() PUSH(POP() < POP()) end,

	--LESS THAN OR EQUAL
	function() PUSH(POP() <= POP()) end,

	--BOOLEAN NOT
	function() PUSH(not std.bool(POP())) end,

	--CHECK IF VARIABLE EXISTS
	function() PUSH(VARS[POP()] ~= nil) end,

	--IRANDOM
	function()
		local v = POP()
		local max, min = std.num(v[1]), std.num(v[2])
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
		local v, min, i = POP()

		for i = 1, #v do
			if type(v[i]) == 'table' then
				local k
				for k = 1, #v[i] do
					if not min or min < std.num(v[i][k]) then min = std.num(v[i][k]) end
				end
			elseif not min or min < std.num(v[i]) then
				min = std.num(v[i])
			end
		end
	end,

	--MAX of arbitrary number of arguments
	function()
		local v, max, i = POP()

		for i = 1, #v do
			if type(v[i]) == 'table' then
				local k
				for k = 1, #v[i] do
					if not max or max > std.num(v[i][k]) then min = std.num(v[i][k]) end
				end
			elseif not max or max > std.num(v[i]) then
				min = std.num(v[i])
			end
		end
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
	function() PUSH(std.type(POP())) end,

	--BOOL
	function() PUSH(std.bool(POP())) end,

	--NUM
	function() PUSH(std.num(POP())) end,

	--STR
	function() PUSH(std.str(POP())) end,

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
	[0] = function(line, p1, p2) functions[p1](line, p2) end,

	--SET VARIABLE
	[2] = function(line, p1, p2)
		VARS[p1] = POP()
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
		output_array(command_array, 2)
		return true --Suppress regular "continue" output
	end,

	--PUSH LAST COMMAND RESULT TO THE STACK
	[7] = function(line, p1, p2)
		PUSH(LAST_CMD_RESULT)
	end,

	--PUSH THE CURRENT INSTRUCTION INDEX TO THE STACK
	[8] = function(line, p1, p2)
		PUSH(CURRENT_INSTRUCTION)
	end,

	--POP THE NEW INSTRUCTION INDEX FROM THE STACK (GOTO THAT INDEX)
	[9] = function(line, p1, p2)
		CURRENT_INSTRUCTION = POP()
	end,
}