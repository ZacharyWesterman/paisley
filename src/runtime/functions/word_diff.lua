return function(vm)
	local v = vm.pop()
	vm.push(lev(std.str(v[1]), std.str(v[2])))
end
