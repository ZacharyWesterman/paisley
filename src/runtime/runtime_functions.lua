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
	require 'src.runtime.functions.jump',
	require 'src.runtime.functions.jumpifnil',
	require 'src.runtime.functions.jumpiffalse',
	require 'src.runtime.functions.explode',
	require 'src.runtime.functions.implode',
	require 'src.runtime.functions.superimplode',
	require 'src.runtime.functions.add',
	require 'src.runtime.functions.sub',
	require 'src.runtime.functions.mul',
	require 'src.runtime.functions.div',
	require 'src.runtime.functions.rem',
	require 'src.runtime.functions.length',
	require 'src.runtime.functions.arrayindex',
	require 'src.runtime.functions.arrayslice',
	require 'src.runtime.functions.concat',
	require 'src.runtime.functions.booland',
	require 'src.runtime.functions.boolor',
	require 'src.runtime.functions.boolxor',
	require 'src.runtime.functions.inarray',
	require 'src.runtime.functions.strlike',
	require 'src.runtime.functions.equal',
	require 'src.runtime.functions.notequal',
	require 'src.runtime.functions.greater',
	require 'src.runtime.functions.greaterequal',
	require 'src.runtime.functions.less',
	require 'src.runtime.functions.lessequal',
	require 'src.runtime.functions.boolnot',
	require 'src.runtime.functions.varexists',
	require 'src.runtime.functions.random_int',
	require 'src.runtime.functions.random_float',
	require 'src.runtime.functions.word_diff',
	require 'src.runtime.functions.dist',
	require 'src.runtime.functions.sin',
	require 'src.runtime.functions.cos',
	require 'src.runtime.functions.tan',
	require 'src.runtime.functions.asin',
	require 'src.runtime.functions.acos',
	require 'src.runtime.functions.atan',
	require 'src.runtime.functions.atan2',
	require 'src.runtime.functions.sqrt',
	require 'src.runtime.functions.sum',
	require 'src.runtime.functions.mult',
	require 'src.runtime.functions.pow',
	require 'src.runtime.functions.min',
	require 'src.runtime.functions.max',
	require 'src.runtime.functions.split',
	require 'src.runtime.functions.join',
	require 'src.runtime.functions.type',
	require 'src.runtime.functions.bool',
	require 'src.runtime.functions.num',
	require 'src.runtime.functions.str',
	require 'src.runtime.functions.floor',
	require 'src.runtime.functions.ceil',
	require 'src.runtime.functions.round',
	require 'src.runtime.functions.abs',
	require 'src.runtime.functions.append',
	require 'src.runtime.functions.index',
	require 'src.runtime.functions.lower',
	require 'src.runtime.functions.upper',
	require 'src.runtime.functions.camel',
	require 'src.runtime.functions.replace',
	require 'src.runtime.functions.json_encode',
	require 'src.runtime.functions.json_decode',
	require 'src.runtime.functions.json_valid',
	require 'src.runtime.functions.b64_encode',
	require 'src.runtime.functions.b64_decode',
	require 'src.runtime.functions.lpad',
	require 'src.runtime.functions.rpad',
	require 'src.runtime.functions.filter',
	require 'src.runtime.functions.matches',
	require 'src.runtime.functions.clocktime',
	require 'src.runtime.functions.reverse',
	require 'src.runtime.functions.sort',
	require 'src.runtime.functions.bytes',
	require 'src.runtime.functions.frombytes',
	require 'src.runtime.functions.merge',
	require 'src.runtime.functions.update',
	require 'src.runtime.functions.insert',
	require 'src.runtime.functions.delete',
	require 'src.runtime.functions.lerp',
	require 'src.runtime.functions.random_element',
	require 'src.runtime.functions.hash',
	require 'src.runtime.functions.object',
	require 'src.runtime.functions.array',
	require 'src.runtime.functions.keys',
	require 'src.runtime.functions.values',
	require 'src.runtime.functions.pairs',
	require 'src.runtime.functions.interleave',
	require 'src.runtime.functions.unique',
	require 'src.runtime.functions.union',
	require 'src.runtime.functions.intersection',
	require 'src.runtime.functions.difference',
	require 'src.runtime.functions.symmetric_difference',
	require 'src.runtime.functions.is_disjoint',
	require 'src.runtime.functions.is_subset',
	require 'src.runtime.functions.is_superset',
	require 'src.runtime.functions.count',
	require 'src.runtime.functions.find',
	require 'src.runtime.functions.flatten',
	require 'src.runtime.functions.smoothstep',
	require 'src.runtime.functions.sinh',
	require 'src.runtime.functions.cosh',
	require 'src.runtime.functions.tanh',
	require 'src.runtime.functions.sign',
	require 'src.runtime.functions.ascii',
	require 'src.runtime.functions.char',
	require 'src.runtime.functions.beginswith',
	require 'src.runtime.functions.endswith',
	require 'src.runtime.functions.to_base',
	require 'src.runtime.functions.time',
	require 'src.runtime.functions.date',
	require 'src.runtime.functions.random_elements',
	require 'src.runtime.functions.match',
	require 'src.runtime.functions.splice',
	require 'src.runtime.functions.uuid',
	require 'src.runtime.functions.glob',
	require 'src.runtime.functions.xml_encode',
	require 'src.runtime.functions.xml_decode',
	require 'src.runtime.functions.log',
	require 'src.runtime.functions.normalize',
	require 'src.runtime.functions.random_weighted',

	--TRIM CHARACTERS FROM A STRING
	function(vm)
		local v = vm.pop()
		local text, chars = std.str(v[1]), std.str(v[2])

		if chars == nil then
			vm.push(text:match('^%s*(.-)%s*$'))
			return
		end

		-- Remove any of a list of chars
		local pattern = '^[' .. std.str(chars):gsub('(%W)', '%%%1') .. ']*(.-)[' ..
			std.str(chars):gsub('(%W)', '%%%1') .. ']*$'
		vm.push(text:match(pattern))
	end,

	require 'src.runtime.functions.modf',

	--CONVERT A NUMERIC STRING FROM ANY BASE TO A NUMBER
	function(vm)
		local v = vm.pop()
		local str_value, base = std.str(v[1]), std.num(v[2])
		if base < 2 or base > 36 then
			error('Error: from_base() base must be between 2 and 36!')
			return
		end
		vm.push(std.from_base(str_value, base))
	end,

	--CHUNK AN ARRAY INTO SUB-ARRAYS OF A GIVEN SIZE
	function(vm)
		local v = vm.pop()
		local array, size = v[1], std.num(v[2])
		if std.type(array) ~= 'array' then
			print('WARNING: chunk() first argument is not an array! Coercing to an empty array.')
			array = {}
		end

		vm.push(std.chunk(array, size))
	end,

	--GET ENVIRONMENT VARIABLE
	function(vm)
		--Environment variables are always null in the plasma build.

		--[[minify-delete]]
		if true then
			vm.push(os.getenv(std.str(vm.pop()[1])))
		else
			--[[/minify-delete]]
			vm.push(nil)
			--[[minify-delete]]
		end
		--[[/minify-delete]]
	end,

	--CONVERT A TIME ARRAY INTO A TIMESTAMP
	function(vm)
		local v = vm.pop()[1]
		if type(v) ~= 'table' then
			vm.push(0)
			return
		end
		vm.push((v[1] or 0) * 3600 + (v[2] or 0) * 60 + (v[3] or 0) + (v[4] or 0) / 1000)
	end,

	require 'src.runtime.functions.fmod',

	--CHECK IF AN ARRAY IS SORTED
	function(vm)
		local array = vm.pop()[1]

		if std.type(array) ~= 'array' then
			vm.push(false)
			return
		end

		local last_element = array[1]
		for i = 2, #array do
			if last_element > array[i] then
				vm.push(false)
				return
			end
			last_element = array[i]
		end
		vm.push(true)
	end,

	--BITWISE AND
	function(vm) vm.push(std.bitwise['and'](std.num(vm.pop()), std.num(vm.pop()))) end,

	--BITWISE OR
	function(vm) vm.push(std.bitwise['or'](std.num(vm.pop()), std.num(vm.pop()))) end,

	--BITWISE XOR
	function(vm) vm.push(std.bitwise['xor'](std.num(vm.pop()), std.num(vm.pop()))) end,

	--BITWISE NOT
	function(vm) vm.push(std.bitwise['not'](std.num(vm.pop()))) end,

	--[[minify-delete]]
	--CONVERT A DATETIME OBJECT TO A UNIX TIMESTAMP
	function(vm)
		local dt = vm.pop()[1]
		if std.type(dt) ~= 'object' then
			vm.push(0)
			return
		end
		vm.push(os.time {
			year = dt.date and dt.date[3],
			month = dt.date and dt.date[2],
			day = dt.date and dt.date[1],
			hour = dt.time and dt.time[1],
			min = dt.time and dt.time[2],
			sec = dt.time and dt.time[3],
		})
	end,

	--CONVERT A UNIX TIMESTAMP TO A DATETIME OBJECT
	function(vm)
		local timestamp = vm.pop()[1]
		local datetime = std.object()
		if std.type(timestamp) ~= 'number' then
			vm.push(datetime)
			return
		end
		local dt = os.date('*t', timestamp)
		datetime.date = { dt.day, dt.month, dt.year }
		datetime.time = { dt.hour, dt.min, dt.sec }
		vm.push(datetime)
	end,

	--GET THE CURRENT EPOCH TIME
	function(vm)
		vm.pop()
		vm.push(os.time())
	end,

	--LIST ALL FILES THAT MATCH A GLOB PATTERN
	function(vm)
		local pattern = std.str(vm.pop()[1])

		local lfs = fs.rocks.lfs
		if not lfs then
			error('Error in file_glob(): Lua lfs module not installed!')
			return
		end

		vm.push(fs.glob_files(pattern))
	end,

	--CHECK IF A FILE EXISTS
	function(vm) vm.push(fs.file_exists(std.str(vm.pop()[1]))) end,

	--GET FILE SIZE
	function(vm) vm.push(fs.file_size(std.str(vm.pop()[1]))) end,

	--READ FILE CONTENTS
	function(vm) vm.push(fs.file_read(std.str(vm.pop()[1]))) end,

	--WRITE FILE CONTENTS
	function(vm)
		local v = vm.pop()
		vm.push(fs.file_write(std.str(v[1]), std.str(v[2]), false))
	end,

	--APPEND TO FILE
	function(vm)
		local v = vm.pop()
		vm.push(fs.file_write(std.str(v[1]), std.str(v[2]), true))
	end,

	--DELETE A FILE
	function(vm) vm.push(fs.file_delete(std.str(vm.pop()[1]))) end,

	--MAKE A DIRECTORY
	function(vm)
		local v = vm.pop()
		vm.push(fs.dir_create(std.str(v[1]), std.bool(v[2])))
	end,

	--LIST FILES IN A DIRECTORY
	function(vm)
		local v = vm.pop()
		vm.push(fs.dir_list(std.str(v[1])))
	end,

	--DELETE A DIRECTORY
	function(vm)
		local v = vm.pop()
		vm.push(fs.dir_delete(std.str(v[1]), std.bool(v[2])))
	end,

	--GET THE TYPE OF A FILESYSTEM OBJECT
	function(vm) vm.push(fs.file_type(std.str(vm.pop()[1]))) end,

	--STAT A FILE
	function(vm) vm.push(fs.file_stat(std.str(vm.pop()[1]))) end,

	--COPY A FILE
	function(vm)
		local v = vm.pop()
		vm.push(fs.file_copy(std.str(v[1]), std.str(v[2]), std.bool(v[3])))
	end,

	--MOVE A FILE
	function(vm)
		local v = vm.pop()
		vm.push(fs.file_move(std.str(v[1]), std.str(v[2]), std.bool(v[3])))
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
	--vm.push VALUE ONTO STACK
	require 'src.runtime.actions.push',
	--POP VALUE FROM STACK
	require 'src.runtime.actions.pop',
	--RUN COMMAND
	require 'src.runtime.actions.run_command',
	--vm.push LAST COMMAND RESULT TO THE STACK
	require 'src.runtime.actions.push_cmd_result',
	--vm.push THE CURRENT INSTRUCTION INDEX TO THE STACK
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
	--vm.push CATCH RETURN LOCATION ONTO EXCEPTION STACK
	require 'src.runtime.actions.push_catch_loc',
	--INSERT VALUE INTO VARIABLE
	require 'src.runtime.actions.variable_insert',
	--DESTRUCTURE VALUE INTO A LIST OF VARIABLES
	require 'src.runtime.actions.destructure',
}

return vm
