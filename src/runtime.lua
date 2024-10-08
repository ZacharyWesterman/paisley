--[[
	This is the Paisley bytecode interpreter runtime.
	This module will run bytecode generated by the Paisley compiler.
]]

require "src.shared.stdlib"
require "src.shared.closest_word"
require "src.shared.json"
require "src.runtime.runtime_functions"


FILE = V2

--[[
	Command format is a string array, each element formatted as follows:
	"COMMAND_NAME:RETURN_TYPE"
	Where RETURN_TYPE is a Paisley data type, not a Lua type.

	Paisley types are one of the following:
		null
		boolean
		number
		string
		array
		any

	Note that this IS case-sensitive!
]]
ALLOWED_COMMANDS = V3
if not SIGNATURE then function SIGNATURE(x) return x end end --Dummy signature definition, just so runtime doesn't give an error.
require "src.shared.builtin_commands"

--[[RUN THIS TO LOAD CODE]]
function INIT()
	INSTRUCTIONS = json.parse(V1)

	--re-populate constants from the lookup table
	local constants = table.remove(INSTRUCTIONS)
	for i = 1, #INSTRUCTIONS do
		local id, value = INSTRUCTIONS[i][1], INSTRUCTIONS[i][3]
		if (id == 2 or id == 3 or id == 4) and value ~= nil and constants[value] ~= nil then
			INSTRUCTIONS[i][3] = constants[value]
		end
	end

	CURRENT_INSTRUCTION = 0
	LAST_CMD_RESULT = nil
	RANDOM_SEED = V4
	math.randomseed(RANDOM_SEED)
	math.random() --First random number after seeding is often not truly random, so clear it out
	STACK = {}
	VARS = {}
	INSTR_STACK = {}
	output(0, 1)
end

function ITER()
	CURRENT_INSTRUCTION = CURRENT_INSTRUCTION + 1
	local I = INSTRUCTIONS[CURRENT_INSTRUCTION]
	LAST_CMD_RESULT = V5

	if I == nil then
		output(nil, 3) --Program successfully completed
	else
		output(I[2], 8) --Output line number
		local external_cmd = COMMANDS[I[1]](I[2], I[3], I[4])
		if not external_cmd then
			return true
		end
	end

	return false
end

--[[RUN THIS WHILE OUTPUT IS COMING FROM (1) OR WHEN COMMAND RETURNS]]
function RUN()
	---@diagnostic disable-next-line
	if type(V8) == 'number' and V8 > 0 then MAX_ITER = math.ceil(V8) end

	for i = 1, MAX_ITER do
		if not ITER() then return end
	end

	local I = INSTRUCTIONS[CURRENT_INSTRUCTION]
	if I then
		output(1, 1)
	end
end

INIT()
