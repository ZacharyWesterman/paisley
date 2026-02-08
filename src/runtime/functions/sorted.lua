return function(vm)
	local array = vm.pop()[1]

	if std.type(array) ~= 'array' then
		vm.push(false)
		return
	end

	local last_element = array[1]
	for i = 2, #array do
		if last_element > array[i] then
			vm.push(false)
			return
		end
		last_element = array[i]
	end
	vm.push(true)
end
