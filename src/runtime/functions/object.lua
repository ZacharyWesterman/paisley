return function(vm)
	local result, array = std.object(), vm.pop()[1]
	if type(array) == 'table' then
		for i = 1, #array, 2 do
			result[std.str(array[i])] = array[i + 1]
		end
	end
	vm.push(result)
end
