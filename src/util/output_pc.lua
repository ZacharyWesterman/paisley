local fs = require "src.util.filesystem"
local json = require "src.shared.json"

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
		-- os.execute('sleep 0.01') --emulate behavior in Plasma where program execution pauses periodicaly to avoid lag.
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

		if fs.rocks.socket then
			sec_since_midnight = sec_since_midnight + (math.floor(fs.rocks.socket.gettime() * 1000) % 1000 / 1000)
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

			if fs.rocks.socket then
				sec_since_midnight = sec_since_midnight + (math.floor(fs.rocks.socket.gettime() * 1000) % 1000 / 1000)
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
			io.stderr:write(args)
		elseif cmd == 'stdin' then
			V5 = io.read('*l')
		elseif cmd == 'clear' then
			os.execute('clear')
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
		local old_dir = fs.pwd()

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
		if CMD_LAST_RESULT['='] == true and value[2]:sub(1, 5) == '"cd" ' then
			WORKING_DIR = WORKING_DIR .. '/' .. value[2]:sub(7):match('^[^"]+')
			fs.cd(WORKING_DIR)
		end
	else
		print(port, json.stringify(value))
	end
end

function output_array(value, port) output(value, port) end
