return function(vm)
	local v = vm.pop()
	local result = {}
	local value = math.floor(std.num(v[1]))
	for i = math.min(4, std.num(v[2])), 1, -1 do
		result[i] = value % 256
		value = math.floor(value / 256)
	end
	vm.push(result)
end
