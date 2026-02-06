MAX_ITER = 100 --Max number of instructions to run before pausing execution (performance reasons mostly)

NULL = {}

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
	require 'src.runtime.functions.trim',
	require 'src.runtime.functions.modf',
	require 'src.runtime.functions.from_base',
	require 'src.runtime.functions.chunk',
	require 'src.runtime.functions.env_get',
	require 'src.runtime.functions.timestamp',
	require 'src.runtime.functions.fmod',
	require 'src.runtime.functions.sorted',
	require 'src.runtime.functions.bitwise_and',
	require 'src.runtime.functions.bitwise_or',
	require 'src.runtime.functions.bitwise_xor',
	require 'src.runtime.functions.bitwise_not',

	--[[minify-delete]]
	require 'src.runtime.functions.toepoch',
	require 'src.runtime.functions.fromepoch',
	require 'src.runtime.functions.epochnow',
	require 'src.runtime.functions.file_glob',
	require 'src.runtime.functions.file_exists',
	require 'src.runtime.functions.file_size',
	require 'src.runtime.functions.file_read',
	require 'src.runtime.functions.file_write',
	require 'src.runtime.functions.file_append',
	require 'src.runtime.functions.file_delete',
	require 'src.runtime.functions.dir_create',
	require 'src.runtime.functions.dir_list',
	require 'src.runtime.functions.dir_delete',
	require 'src.runtime.functions.file_type',
	require 'src.runtime.functions.file_stat',
	require 'src.runtime.functions.file_copy',
	require 'src.runtime.functions.file_move',
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
