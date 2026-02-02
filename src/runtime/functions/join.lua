return function(vm)
	local v = vm.pop()
	vm.push(std.join(v[1], std.str(v[2])))
end
