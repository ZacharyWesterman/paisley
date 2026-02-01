return function(vm, line, p1, p2)
	table.insert(EXCEPT_STACK, {
		instr = p1,
		stack = #STACK,
		instr_stack = #INSTR_STACK,
	})
end
