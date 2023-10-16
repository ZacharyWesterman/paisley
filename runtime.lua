--[[
	This is the Paisley bytecode interpreter runtime.
	This module will run bytecode generated by the Paisley compiler.
]]

require "stdlib"
require "json"

--TEMP: read bytecode from stdin. only for testing
local INSTRUCTIONS = json.parse(io.read())
local CURRENT_INSTRUCTION = 0
local LAST_CMD_RESULT = '<NOTHING>'

local NULL = {}
local STACK = {}
local VARS = {}

local function POP()
	local val = table.remove(STACK)
	if val == NULL then return nil end
	return val
end

local function PUSH(value)
	if val == nil then
		table.insert(STACK, NULL)
	else
		table.insert(value)
	end
end

local functions = {

}

--[[ INSTRUCTION LAYOUT
	instr = {
		command,
		line number,
		param1,
		param2,
	}
]]

local commands = {
	--CALL
	[0] = function(line, p1, p2) functions[p1](line, p2) end,

	--SET VARIABLE
	[2] = function(line, p1, p2)
		VARS[p1] = POP()
	end,

	--GET VARIABLE
	[3] = function(line, p1, p2)
		PUSH(VARS[p1])
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
		--[[What to do here? Command will delay execution, to be resumed once the command finishes]]
	end,

	--PUSH LAST COMMAND RESULT TO THE STACK
	[7] = function(line, p1, p2)
		PUSH(LAST_CMD_RESULT)
	end,

	--PUSH THE CURRENT INSTRUCTION INDEX TO THE STACK
	[8] = function(line, p1, p2)
		PUSH(#INSTRUCTIONS)
	end,

	--POP THE NEW INSTRUCTION INDEX FROM THE STACK (GOTO THAT INDEX)
	[9] = function(line, p1, p2)
		CURRENT_INSTRUCTION = POP()
	end,
}

print(std.debug_str(INSTRUCTIONS))