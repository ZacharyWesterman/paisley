#!/usr/bin/env lua

--Set up vars for testing
V2 = nil --filename
V3 = nil --non-builtin commands

DEBUG_EXTRA = false
for i, v in ipairs(arg) do
	if v:sub(1,1) == '-' and v ~= '-' then
		if v == '--extra' then
			DEBUG_EXTRA = true
		end
	else
		V2 = v
	end
end

if V2 == nil then
	error('Error: No input file given. Use `-` to read from stdin, or re-run with `--help` to see all options.')
end

if V2 == '-' then
	V2 = nil
	V1 = io.read('*all') --program text
else
	--Read from file
	local file = io.open(V2)
	if file then
		V1 = file:read('*all')
	else
		error('Error: Cannot open file `'..V2..'`.')
	end
end

COMPILER_DEBUG = true
V3 = {
	"receive"
}

local TRANSFER
function output(data, _)
	TRANSFER = data
end

require "src.compiler"

print_header('Raw Bytecode')
print(TRANSFER)

local DATA, PORT
function output(data, port)
	DATA = data
	PORT = port
end
function output_array(data, port)
	DATA = data
	PORT = port
end

function run_bytecode()
	print()
	print_header('RUNNING BYTECODE')
	V1 = TRANSFER --Serialized bytecode
	V2 = nil --FILE
	V3 = ALLOWED_COMMANDS
	V4 = 0 --RNG seed value
	V5 = nil --LAST CMD RESULT
	PORT = 0
	DATA = nil

	require "src.runtime"

	DEBUG_INSTRUCTION_NUM = 1
	while PORT ~= 3 do
		os.execute('sleep 1')
		-- os.execute('clear')
		ITER()
		-- if PORT == 6 then
		-- 	if DATA == 1 then V5 = ''
		V5 = {10, 25, 2023}
		DEBUG_INSTRUCTION_NUM = CURRENT_INSTRUCTION
		if bytecode then
			print_bytecode(bytecode)
		end

		print()
		print_header('BEG STACK')
		for i = 1, #STACK do
			if STACK[i] == NULL then print('null') else print(std.debug_str(STACK[i])) end
		end
		print_header('END STACK')

		io.flush()
	end
end

local i
for i = 1, #arg do
	if arg[i] == 'run' then
		run_bytecode()
		break
	end
end
