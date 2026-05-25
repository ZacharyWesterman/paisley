return function(vm, line, param)
	local array = vm.pop()
	local tp = std.type(array)

	if tp == 'object' then
		for key, value in pairs(array) do vm.push(key) end
	elseif tp == 'array' then
		for i = #array, 1, -1 do
			vm.push(array[i])
		end
	elseif tp == 'string' then
		array = std.split(array, '\n')
		for i = #array, 1, -1 do
			vm.push(array[i])
		end
	else
		vm.push(array)
	end
end
