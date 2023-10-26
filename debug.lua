--Set up vars for testing
V1 = io.read('*all') --input expression
V2 = nil --filename
V3 = nil --non-builtin commands

COMPILER_DEBUG = true

local TRANSFER
function output(data, _)
	TRANSFER = data
end

require "compiler"

-- exit() --TEMP

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
V3 = {} --non-builtin commands
V4 = 0 --RNG seed value
V5 = nil --LAST CMD RESULT

require "runtime"

DEBUG_INSTRUCTION_NUM = 1
print(PORT)
while PORT ~= 3 do
	os.execute('sleep 1')
	os.execute('clear')
	ITER()
	DEBUG_INSTRUCTION_NUM = CURRENT_INSTRUCTION
	print_bytecode(bytecode)

	print()
	print_header('BEG STACK')
	for i = 1, #STACK do
		print(std.debug_str(STACK[i]))
	end
	print_header('END STACK')

	io.flush()
end