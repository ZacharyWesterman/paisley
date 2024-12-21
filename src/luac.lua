-- Strips debug information from a dumped chunk
function LUAC_STRIP(dump)
    local version, format, endian, int, size, ins, num = dump:byte(5, 11)
    local subint
    if endian == 1 then
        subint = function(dump, i, l)
            local val = 0
            for n = l, 1, -1 do
                val = val * 256 + dump:byte(i + n - 1)
            end
            return val, i + l
        end
    else
        subint = function(dump, i, l)
            local val = 0
            for n = 1, l, 1 do
                val = val * 256 + dump:byte(i + n - 1)
            end
            return val, i + l
        end
    end
    local strip_function
    strip_function = function(dump)
        local count, offset = subint(dump, 1, size)
        local stripped, dirty = string.rep("\0", size), offset + count
        offset = offset + count + int * 2 + 4
        offset = offset + int + subint(dump, offset, int) * ins
        count, offset = subint(dump, offset, int)
        for n = 1, count do
            local t
            t, offset = subint(dump, offset, 1)
            if t == 1 then
                offset = offset + 1
            elseif t == 4 then
                offset = offset + size + subint(dump, offset, size)
            elseif t == 3 then
                offset = offset + num
            end
        end
        count, offset = subint(dump, offset, int)
        stripped = stripped .. dump:sub(dirty, offset - 1)
        for n = 1, count do
            local proto, off = strip_function(dump:sub(offset, -1))
            stripped, offset = stripped .. proto, offset + off - 1
        end
        offset = offset + subint(dump, offset, int) * int + int
        count, offset = subint(dump, offset, int)
        for n = 1, count do
            offset = offset + subint(dump, offset, size) + size + int * 2
        end
        count, offset = subint(dump, offset, int)
        for n = 1, count do
            offset = offset + subint(dump, offset, size) + size
        end
        stripped = stripped .. string.rep("\0", int * 3)
        return stripped, offset
    end
    return dump:sub(1, 12) .. strip_function(dump:sub(13, -1))
end

function LUAC_DUMP(text)
    local function loadfn()
        local switch = false
        return function()
            if switch then return nil end
            switch = true
            return text
        end
    end

    local fn = load(loadfn())
    if not fn then
        ---@diagnostic disable-next-line
        parse_error(nil, 'COMPILER BUG: Failed to compile Lua runtime into bytecode!')
        error()
    end

    return string.dump(fn)
end

function LUAC_RUNTIME_TEXT(bytecode_text)
    text = 'V1 = "' .. bytecode_text:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"\n'
    text = text .. 'V4 = os.time()\n'
    text = text .. 'V8 = 1000000000000\n'
    text = text .. [[
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
                V5 = CMD_LAST_RESULT[value[1] ]
                return
            end

            --Run new unix command
            CMD_LAST_RESULT = {
                ['!'] = '', --stdout of command
                ['?'] = nil, --result of execution
            }

            local program = io.popen(value[2] .. ' 2>&1', 'r')
            if program then
                local line = program:read('*l')
                while line do
                    if value[1] ~= '!' then print(line) end
                    if #CMD_LAST_RESULT['!'] > 0 then line = '\n' .. line end
                    CMD_LAST_RESULT['!'] = CMD_LAST_RESULT['!'] .. line

                    line = program:read('*l')
                end

                CMD_LAST_RESULT['?'] = program:close()
            end

            V5 = CMD_LAST_RESULT[value[1] ]
        else
            print(port, json.stringify(value))
        end
    end

    function output_array(value, port) output(value, port) end
    ]]
    return text
end

function LUAC_EXEC_TEXT()
    return '\nwhile true do RUN() if not INSTRUCTIONS[CURRENT_INSTRUCTION] then break end end'
end
