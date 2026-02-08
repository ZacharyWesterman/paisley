return function(vm, line, param)
	local array = vm.pop()

	if std.type(array) == 'object' then
		for key, value in pairs(array) do vm.push(key) end
	elseif std.type(array) == 'array' then
		for i = 1, #array do
			local val = array[#array - i + 1]
			vm.push(val)
		end
	else
		vm.push(array)
	end
end
