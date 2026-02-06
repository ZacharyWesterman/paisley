return function(vm)
	local v = vm.pop()
	local array, size = v[1], std.num(v[2])
	if std.type(array) ~= 'array' then
		print('WARNING: chunk() first argument is not an array! Coercing to an empty array.')
		array = {}
	end

	vm.push(std.chunk(array, size))
end
