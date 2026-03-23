return function(vm, line, p1, p2)
	local err = STACK[#STACK]

	if #EXCEPT_STACK == 0 then
		--If exception is not caught, end the program immediately and output the error
		CURRENT_INSTRUCTION = #INSTRUCTIONS + 1

		local msg = ''

		---@diagnostic disable-next-line
		if FILE and #FILE > 0 then
			msg = '["' .. err.file .. '": ' .. err.line .. '] ' .. err.message
		else
			msg = '[line ' .. err.line .. '] ' .. err.message
		end
		output_array({ "error", 'ERROR: ' .. msg .. '\nError not caught, program terminated.' }, 7)

		return
	end

	--Otherwise, we are catching exceptions.

	--Unroll program stack
	local catch = table.remove(EXCEPT_STACK)
	while #STACK > catch.stack do
		table.remove(STACK)
	end

	--Unroll call stack
	while #INSTR_STACK > catch.instr_stack do
		table.remove(INSTR_STACK) --Remove any function parameters
		table.remove(INSTR_STACK) --Remove stack size value
		local instr_id = table.remove(INSTR_STACK)
		table.insert(err.stack, 1, INSTRUCTIONS[instr_id][2])
	end
	CURRENT_INSTRUCTION = catch.instr

	err.line = err.stack[#err.stack]

	vm.push(err)
end
