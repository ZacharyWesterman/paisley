return function(vm, line, p1, p2)
	table.insert(INSTR_STACK, CURRENT_INSTRUCTION + 1)
	table.insert(INSTR_STACK, #STACK - 1)             --Keep track of how big the stack SHOULD be when returning
	table.insert(INSTR_STACK, STACK[#STACK - (p1 or 0)]) --Append any function parameters (with offset, if any)
end
