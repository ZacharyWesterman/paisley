#!/usr/bin/env lua

--Set up vars for testing
V2 = nil --filename
V3 = nil --non-builtin commands

DEBUG_EXTRA = false
RUN_PROGRAM = false
STEP_PROGRAM = false
for i, v in ipairs(arg) do
	if v:sub(1,1) == '-' and v ~= '-' then
		if v == '--extra' then
			DEBUG_EXTRA = true
		elseif v == '--run' then
			RUN_PROGRAM = true
		elseif v == '--step' then
			STEP_PROGRAM = true
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

if RUN_PROGRAM then
	print()
	print_header('RUNNING BYTECODE')

	local tmp = ALLOWED_COMMANDS

	V1 = json.stringify(bytecode)
	V4 = os.time()
	V5 = nil

	require "src.runtime"
	ALLOWED_COMMANDS = tmp

	ENDED = false
	local socket_installed, socket = pcall(require, 'socket')

	local line_no = 0
	function output(value, port)
		if port == 1 then
			--continue program
			os.execute('sleep 0.01') --emulate behavior in Plasma where program execution pauses periodicaly to avoid lag.
		elseif port == 2 then
			--run a non-builtin command (currently not supported outside of Plasma)
			error('Error on line '.. line_no .. ': Cannot run program `' .. std.str(value) .. '`')
		elseif port == 3 then
			ENDED = true --program successfully completed
		elseif port == 4 then
			--delay execution for an amount of time
			os.execute('sleep ' .. value)
			V5 = nil
		elseif port == 5 then
			--get current time (seconds since midnight)
			local date = os.date('*t', os.time())
			local sec_since_midnight = date.hour*3600 + date.min*60 + date.sec

			if socket_installed then
				sec_since_midnight = sec_since_midnight + (math.floor(socket.gettime() * 1000) % 1000 / 1000)
			end

			V5 = sec_since_midnight --command return value
		elseif port == 6 then
			if value == 2 then
				--get system date (day, month, year)
				local date = os.date('*t', os.time())
				V5 = {date.day, date.month, date.year} --command return value
			elseif value == 1 then
				--get system time (seconds since midnight)
				local date = os.date('*t', os.time())
				local sec_since_midnight = date.hour*3600 + date.min*60 + date.sec

				if socket_installed then
					sec_since_midnight = sec_since_midnight + (math.floor(socket.gettime() * 1000) % 1000 / 1000)
				end

				V5 = sec_since_midnight --command return value
			end
		elseif port == 7 then
			V5 = nil
			--Print text or error
			local cmd = value[1]
			table.remove(value, 1)
			local args = std.str(value)
			if cmd == 'stdout' then
				io.write(args)
			elseif cmd == 'stderr' then
				io.write(io.stderr, args)
			elseif cmd == 'stdin' then
				V5 = io.read('*l')
			else
				print(args)
			end
			io.flush()
		elseif port == 8 then
			--value is current line number
		else
			print(port, json.stringify(value))
		end
	end

	function output_array(value, port) output(value, port) end

	while not ENDED do
		if not STEP_PROGRAM then os.execute('sleep 1') end

		ITER()

		DEBUG_INSTRUCTION_NUM = CURRENT_INSTRUCTION
		if bytecode then
			print_bytecode(bytecode)
		end

		print()
		print_header('BEG STACK')
		for i = 1, #STACK do
			if STACK[i] == NULL then print('null') else print(std.debug_str(STACK[i])) end
		end
		print_header('END STACK / BEG VARS')
		for key, value in pairs(VARS) do
			print(key..' = '.. std.debug_str(value))
		end
		print_header('END VARS')


		io.flush()

		if STEP_PROGRAM then local _ = io.read() end
	end
end
