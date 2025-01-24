#!/usr/bin/env lua

--Set up vars for testing
V2 = nil --filename
V3 = nil --non-builtin commands

DEBUG_EXTRA = false
RUN_PROGRAM = false
STEP_PROGRAM = false
for i, v in ipairs(arg) do
	if v:sub(1, 1) == '-' and v ~= '-' then
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
		error('Error: Cannot open file `' .. V2 .. '`.')
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

local function script_real_path()
	local path = arg[0]
	local windows = package.config:sub(1, 1) == '\\'

	if windows then
		local ffi_installed, ffi = pcall(require, 'ffi')

		if not ffi_installed then return '' end

		ffi.cdef [[
            typedef unsigned long DWORD;
            typedef char CHAR;
            typedef DWORD ( __stdcall *GetFullPathNameA_t )(const CHAR*, DWORD, CHAR*, CHAR**);
        ]]
		local kernel32 = ffi.load("kernel32")
		local MAX_PATH = 260
		local buf = ffi.new("char[?]", MAX_PATH)
		local getFullPathName = ffi.cast("GetFullPathNameA_t", kernel32.GetFullPathNameA)
		local length = getFullPathName(path, MAX_PATH, buf, nil)
		if length == 0 then
			return '' -- Failed to get path
		else
			return ffi.string(buf, length)
		end
	else
		-- If on Linux, resolve symbolic links
		local resolvedPath = io.popen("readlink -f " .. path):read("*a")
		if resolvedPath then
			return resolvedPath:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
		else
			return ''                             -- Failed to get path
		end
	end
end

local dir = script_real_path():match('(.*[/\\])')
if dir == nil then dir = '' end

function STDLIB(filename)
	if dir == nil then return nil, filename end

	local fname = dir .. 'stdlib/' .. filename:gsub('%.', '/')
	local fp = io.open(fname .. '.pai')
	if fp then
		return fp, fname .. '.pai'
	end
	return io.open(fname), fname .. '.paisley'
end

local LFS_INSTALLED, LFS = pcall(require, 'LFS')
local zlib_installed, zlib = pcall(require, 'zlib')

local old_working_dir = nil
WORKING_DIR = ''
if LFS_INSTALLED and dir ~= nil then
	old_working_dir = LFS.currentdir()
	WORKING_DIR = old_working_dir
	LFS.chdir(dir)
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
	local CMD_LAST_RESULT = {
		['='] = nil, --result of execution
		['?'] = '', --stdout of command
		['!'] = '', --stderr of command
		['?!'] = '', --stdout and stderr of command
	}

	local TMP1 = '.paisley.program.tmp.stdout'
	local TMP2 = '.paisley.program.tmp.stderr'

	function output(value, port)
		if port == 1 then
			--continue program
			os.execute('sleep 0.01') --emulate behavior in Plasma where program execution pauses periodicaly to avoid lag.
		elseif port == 2 then
			--run a non-builtin command (currently not supported outside of Plasma)
			error('Error on line ' .. line_no .. ': Cannot run program `' .. std.str(value) .. '`')
		elseif port == 3 then
			ENDED = true --program successfully completed
		elseif port == 4 then
			--delay execution for an amount of time
			local exit_code = os.execute('sleep ' .. value)
			if exit_code ~= 0 and exit_code ~= true then ENDED = true end

			V5 = nil
		elseif port == 5 then
			--get current time (seconds since midnight)
			local date = os.date('*t', os.time())
			local sec_since_midnight = date.hour * 3600 + date.min * 60 + date.sec

			if socket_installed then
				sec_since_midnight = sec_since_midnight + (math.floor(socket.gettime() * 1000) % 1000 / 1000)
			end

			V5 = sec_since_midnight --command return value
		elseif port == 6 then
			if value == 2 then
				--get system date (day, month, year)
				local date = os.date('*t', os.time())
				V5 = { date.day, date.month, date.year } --command return value
			elseif value == 1 then
				--get system time (seconds since midnight)
				local date = os.date('*t', os.time())
				local sec_since_midnight = date.hour * 3600 + date.min * 60 + date.sec

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
		elseif port == 9 then
			--Get the output of the last run unix command
			if value[2] == '' then
				V5 = CMD_LAST_RESULT[value[1]]
				return
			end

			--Run new unix command
			CMD_LAST_RESULT = {
				['='] = nil, --result of execution
				['?'] = '', --stdout of command
				['!'] = '', --stderr of command
				['?!'] = '', --stdout and stderr of command
			}

			local cmd = value[2]

			--By default (both captured), both stdout and stderr will just go to temp files and not be streamed.
			local pipe = cmd .. '2>' .. TMP2 .. ' 1>' .. TMP1
			--If capturing stderr, then stderr will be in file, stdout will be streamed.
			if value[1] == '!' then pipe = cmd .. '2>' .. TMP2 .. ' | tee ' .. TMP1 end
			--If capturing stdout, then stdout will be in file, stderr will be streamed.
			if value[1] == '?' then pipe = cmd .. '1>' .. TMP1 .. ' 2>&1 | tee ' .. TMP2 end
			--If capturing neither, then both will be streamed.
			if value[1] == '=' then pipe = '{ { ' .. cmd .. '; } | tee ' .. TMP1 .. '; } 2>&1 | tee ' .. TMP2 end

			cmd = pipe

			--Stash working dir
			local old_dir = ''
			if LFS_INSTALLED then
				old_dir = LFS.currentdir()
				LFS.chdir(WORKING_DIR)
			end

			local program = io.popen(cmd, 'r')
			if program then
				local chr = program:read(1)
				while chr do
					io.stdout:write(chr)
					chr = program:read(1)
				end

				--Read stream results from files
				local stdout = io.open(TMP1, 'r')
				local stderr = io.open(TMP2, 'r')
				if stdout then
					CMD_LAST_RESULT['?'] = stdout:read('*all')
					stdout:close()
					os.remove(TMP1)
				end
				if stderr then
					CMD_LAST_RESULT['!'] = stderr:read('*all')
					stderr:close()
					os.remove(TMP2)
				end
				CMD_LAST_RESULT['?!'] = CMD_LAST_RESULT['?'] .. CMD_LAST_RESULT['!']

				--Trim trailing newline from command capture
				for _, i in pairs({ '?', '!', '?!' }) do
					if CMD_LAST_RESULT[i]:sub(#CMD_LAST_RESULT[i]) == '\n' then
						CMD_LAST_RESULT[i] = CMD_LAST_RESULT[i]:sub(1, #CMD_LAST_RESULT[i] - 1)
					end
				end

				--Store exec result
				CMD_LAST_RESULT['='] = program:close()
				io.stdout:flush()
			end

			V5 = CMD_LAST_RESULT[value[1]]

			--Restore working dir
			if LFS_INSTALLED then
				-- print(CMD_LAST_RESULT['='], value[2])
				if CMD_LAST_RESULT['='] == true and value[2]:sub(1, 5) == '"cd" ' then
					WORKING_DIR = WORKING_DIR .. '/' .. value[2]:sub(7):match('^[^"]+')
				end
				LFS.chdir(old_dir)
			end
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
			print(key .. ' = ' .. std.debug_str(value))
		end
		print_header('END VARS')


		io.flush()

		if STEP_PROGRAM then local _ = io.read() end
	end
end
