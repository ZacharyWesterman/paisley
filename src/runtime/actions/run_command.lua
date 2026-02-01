return function(vm, line, p1, p2)
	local command_array = vm.pop()
	local cmd_array = {}
	for i = 1, #command_array do
		if std.type(command_array[i]) == 'array' then
			for k = 1, #command_array[i] do
				table.insert(cmd_array, std.str(command_array[i][k]))
			end
		elseif std.type(command_array[i]) == 'object' then
			for key, value in pairs(command_array[i]) do
				table.insert(cmd_array, std.str(key))
				table.insert(cmd_array, std.str(value))
			end
		else
			table.insert(cmd_array, std.str(command_array[i]))
		end
	end
	command_array = cmd_array
	local cmd_name = std.str(command_array[1])

	if not ALLOWED_COMMANDS[cmd_name] and not BUILTIN_COMMANDS[cmd_name] then
		--If command doesn't exist, try to help user by guessing the closest match (but still throw an error)
		local msg = 'Unknown command "' .. cmd_name .. '"'
		local guess = closest_word(cmd_name, ALLOWED_COMMANDS, 4)
		if guess == nil or guess == '' then
			guess = closest_word(cmd_name, BUILTIN_COMMANDS, 4)
		end

		if guess ~= nil and guess ~= '' then
			msg = msg .. ' (did you mean "' .. guess .. '"?)'
		end
		vm.runtime_error(line, msg)
	end

	if not ALLOWED_COMMANDS[cmd_name] then
		if cmd_name == 'sleep' then
			local amt = math.max(0.02, std.num(command_array[2])) - 0.02
			output(amt, 4)
		elseif cmd_name == 'time' then
			output(nil, 5)
		elseif cmd_name == 'systime' then
			output(1, 6)
		elseif cmd_name == 'sysdate' then
			output(2, 6)
		elseif cmd_name == 'print' --[[minify-delete]] or cmd_name == 'stdin' or cmd_name == 'stdout' or cmd_name == 'stderr' or cmd_name == 'clear' --[[/minify-delete]] then
			table.remove(command_array, 1)
			local msg = std.join(command_array, ' ')
			output_array({ cmd_name, msg }, 7)
		elseif cmd_name == 'error' then
			table.remove(command_array, 1)
			local msg = std.join(command_array, ' ')

			if #EXCEPT_STACK > 0 then
				--if exception is caught, unroll the stack and return to the catch block

				local err = std.object()
				err.message = msg
				err.stack = { line }

				--Unroll program stack
				local catch = table.remove(EXCEPT_STACK)
				while #STACK > catch.stack do
					table.remove(STACK)
				end

				--Unroll call stack
				while #INSTR_STACK > catch.instr_stack do
					table.remove(INSTR_STACK) --Remove any subroutine parameters
					table.remove(INSTR_STACK) --Remove stack size value
					local instr_id = table.remove(INSTR_STACK)
					table.insert(err.stack, 1, INSTRUCTIONS[instr_id][2])
				end
				CURRENT_INSTRUCTION = catch.instr

				err.line = table.remove(err.stack, 1)

				vm.push(err)
				return false --Don't output the error
			else
				--If exception is not caught, end the program immediately and output the error
				CURRENT_INSTRUCTION = #INSTRUCTIONS + 1

				---@diagnostic disable-next-line
				if FILE and #FILE > 0 then
					msg = '["' .. FILE .. '": ' .. line .. '] ' .. msg
				else
					msg = '[line ' .. line .. '] ' .. msg
				end
				output_array({ "error", 'ERROR: ' .. msg .. '\nError not caught, program terminated.' }, 7)
			end

			--[[minify-delete]]
		elseif cmd_name == '!' or cmd_name == '?' or cmd_name == '?!' or cmd_name == '=' then
			table.remove(command_array, 1)
			--Quote and escape all params, this will be run thru shell
			local text = ''
			for i = 1, #cmd_array do
				local cmd_text = cmd_array[i]
				if cmd_text:sub(1, #RAW_SH_TEXT_SENTINEL) == RAW_SH_TEXT_SENTINEL then
					cmd_text = cmd_text:sub(#RAW_SH_TEXT_SENTINEL + 1)
					text = text .. cmd_text
				else
					cmd_text = cmd_text:gsub('\\', '\\\\'):gsub(
						'"', '\\"'):gsub('%$', '\\$'):gsub('`', '\\`'):gsub('!', '\\!')
					--Escape strings correctly in powershell
					if WINDOWS then cmd_text = cmd_text:gsub('\\"', '`"') end
					text = text .. '"' .. cmd_text .. '" '
				end
			end
			output_array({ cmd_name, text }, 9)
			--[[/minify-delete]]
		elseif cmd_name == '.' then
			--No-op (results are calculated but discarded)
		else
			vm.runtime_error(line, 'RUNTIME BUG: No logic implemented for built-in command "' .. command_array[1] .. '"')
		end
	else
		output_array(command_array, 2)
	end
	return true --Suppress regular "continue" output
end
