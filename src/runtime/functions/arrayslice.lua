return function(vm, line, p1)
	local stop, start, step = std.num(vm.pop()), std.num(vm.pop()), 1
	if p1 then step = std.num(vm.pop()) end

	local array = {}

	--For performance, limit how big slices can be.
	if (stop - start) / step > std.MAX_ARRAY_LEN then
		print('WARNING: line ' ..
			line ..
			': Attempt to create an array of ' ..
			(stop - start) .. ' elements (max is ' .. std.MAX_ARRAY_LEN .. '). Array truncated.')
		stop = start + std.MAX_ARRAY_LEN
	end

	for i = start, stop, step do
		table.insert(array, i)
	end
	vm.push(array)
end
