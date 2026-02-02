return function(vm, line)
	local stop, start = std.num(vm.pop()), std.num(vm.pop())
	local array = {}

	--For performance, limit how big slices can be.
	if stop - start > std.MAX_ARRAY_LEN then
		print('WARNING: line ' ..
			line ..
			': Attempt to create an array of ' ..
			(stop - start) .. ' elements (max is ' .. std.MAX_ARRAY_LEN .. '). Array truncated.')
		stop = start + std.MAX_ARRAY_LEN
	end

	for i = start, stop do
		table.insert(array, i)
	end
	vm.push(array)
end
