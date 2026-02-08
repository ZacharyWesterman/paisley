return function(vm)
	local v = vm.pop()
	local max, min = std.num(v[1]), std.num(v[2])
	vm.push((math.random() * (max - min)) + min)
end
