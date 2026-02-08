return function(vm)
	local v = vm.pop()
	vm.push(std.filter(std.str(v[1]), std.str(v[2])))
end
