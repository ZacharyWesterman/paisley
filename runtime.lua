--[[
	This is the Paisley bytecode interpreter runtime.
	This module will run bytecode generated by the Paisley compiler.
]]

require "stdlib"
require "closest_word"
require "json"
require "runtime_functions"

--[[RUN THIS TO LOAD CODE]]
function INIT()
	INSTRUCTIONS = json.parse(V1)
	CURRENT_INSTRUCTION = 0
	LAST_CMD_RESULT = nil
	RANDOM_SEED = std.num(std.str(V2):reverse())
	math.randomseed(RANDOM_SEED)
	STACK = {}
	VARS = {}
	NULL = {}
	output(0, 1)
end

function ITER()
	CURRENT_INSTRUCTION = CURRENT_INSTRUCTION + 1
	local I = INSTRUCTIONS[CURRENT_INSTRUCTION]
	LAST_CMD_RESULT = V2

	if I == nil then
		output(nil, 3) --Program successfully completed
	else
		if not commands[I[1]](I[2], I[3], I[4]) then
			output(I[3], 1)
			return true
		end
	end

	return false
end

--[[RUN THIS WHILE OUTPUT IS COMING FROM (1) OR WHEN COMMAND RETURNS]]
function RUN()
	local i
	for i = 1, MAX_ITER do
		if not ITER() then break end
	end
end

INIT()