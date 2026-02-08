return function(vm, line, param)
	if param == nil then
		CURRENT_INSTRUCTION = vm.pop()
	else
		CURRENT_INSTRUCTION = param
	end
end
