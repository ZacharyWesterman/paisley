return function(vm)
	local v = vm.pop()
	local result = std.array()
	if type(v[1]) ~= 'table' then v[1] = { v[1] } end

	for i = 1, math.min(std.num(v[2]), #v[1]) do
		local index = math.random(1, #v[1])

		--To make sure that no elements repeat,
		--Remove elements from source and insert them in dest.
		table.insert(result, table.remove(v[1], index))
	end

	vm.push(result)
end
