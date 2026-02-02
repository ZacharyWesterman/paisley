return function(vm)
	local val = vm.pop()
	if type(val) == 'table' then vm.push(#val) else vm.push(#std.str(val)) end
end
