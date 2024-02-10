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
require "src.shared.builtin_commands"

--[[RUN THIS TO LOAD CODE]]
function INIT()
	INSTRUCTIONS = json.parse(V1)
	CURRENT_INSTRUCTION = 0
	LAST_CMD_RESULT = nil
	RANDOM_SEED = std.num(std.str(V4):reverse())
	math.randomseed(RANDOM_SEED)
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
		output(I[2], 8)
		local external_cmd = commands[I[1]](I[2], I[3], I[4])
		if not external_cmd then
			return true
		end
	end

	return false
end

--[[RUN THIS WHILE OUTPUT IS COMING FROM (1) OR WHEN COMMAND RETURNS]]
function RUN()
	local i
	for i = 1, MAX_ITER do
		if not ITER() then return end
	end

	local I = INSTRUCTIONS[CURRENT_INSTRUCTION]
	if I then
		output(1, 1)
	end
end

INIT()