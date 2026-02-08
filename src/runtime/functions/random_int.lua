return function(vm)
	local v = vm.pop()
	local min, max = std.num(v[1]), std.num(v[2])
	vm.push(math.random(math.floor(min), math.floor(max)))
end
