return function(vm)
	local v = vm.pop()
	local vector, weights = v[1], v[2]
	if std.type(vector) ~= 'array' then
		vector = { std.num(vector) }
	end
	if std.type(weights) ~= 'array' then
		weights = { std.num(weights) }
	end
	vm.push(std.random_weighted(vector, weights))
end
