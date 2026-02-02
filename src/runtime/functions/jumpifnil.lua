return function(vm, line, param)
	if STACK[#STACK] == NULL then
		CURRENT_INSTRUCTION = param
	end
end
