return function(vm, line, p1, p2)
	local fn = vm.functions[p1 + 1]
	if not fn then
		vm.runtime_error(line, 'RUNTIME BUG: No function found for id "' .. std.str(p1) .. '"')
	else
		fn(vm, line, p2)
	end
end
