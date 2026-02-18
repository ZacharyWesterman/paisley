return function(vm, line, p1, p2)
	table.remove(INSTR_STACK) --Remove any function parameters
	local new_stack_size = table.remove(INSTR_STACK)
	CURRENT_INSTRUCTION = table.remove(INSTR_STACK)

	if not p1 then
		--Put any function return value in the "command return value" slot
		V5 = table.remove(STACK)

		--Shrink stack back down to how big it should be
		while new_stack_size < #STACK do
			table.remove(STACK)
		end
	end
end
