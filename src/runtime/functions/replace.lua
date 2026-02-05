return function(vm)
	local v = vm.pop()
	vm.push(std.join(std.split(std.str(v[1]), std.str(v[2])), std.str(v[3])))
end
