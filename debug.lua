--Set up vars for testing
V1 = io.read('*all') --input expression
V2 = nil --filename
V3 = nil --non-builtin commands

COMPILER_DEBUG = true
V3 = {
	"receive"
}

local TRANSFER
function output(data, _)
	TRANSFER = data
end

require "compiler"

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

print()
print_header('RUNNING BYTECODE')
V1 = TRANSFER --Serialized bytecode
V2 = nil --FILE
V3 = ALLOWED_COMMANDS
V4 = 0 --RNG seed value
V5 = nil --LAST CMD RESULT
PORT = 0
DATA = nil

require "runtime"

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