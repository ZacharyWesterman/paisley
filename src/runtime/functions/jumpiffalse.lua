return function(vm, line, param)
	if std.bool(STACK[#STACK]) == false then CURRENT_INSTRUCTION = param end
end
