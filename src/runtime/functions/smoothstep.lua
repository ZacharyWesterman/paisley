return function(vm)
	local v = vm.pop()
	local value, min, max = std.num(v[1]), std.num(v[2]), std.num(v[3])

	local range = max - min
	value = (math.min(math.max(min, value), max) - min) / range
	value = value * value * (3.0 - 2.0 * value)
	vm.push(value * range + min)
end
