return function(vm)
	local v = vm.pop()
	local ratio, a, b = std.num(v[1]), v[2], v[3]
	if std.type(a) == 'array' or std.type(b) == 'array' then
		if type(a) ~= 'table' then a = { a } end
		if type(b) ~= 'table' then b = { b } end

		local result = {}
		for i = 1, math.min(#a, #b) do
			local start = std.num(a[i])
			local stop = std.num(b[i])
			result[i] = start + ratio * (stop - start)
		end
		vm.push(result)
		return
	end
	a = std.num(a)
	b = std.num(b)
	vm.push(a + ratio * (b - a))
end
