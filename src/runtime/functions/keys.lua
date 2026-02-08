return function(vm)
	local result, object = {}, vm.pop()[1]
	if type(object) == 'table' then
		for key, value in pairs(object) do
			table.insert(result, key)
		end
	end
	vm.push(result)
end
