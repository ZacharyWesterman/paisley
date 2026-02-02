return function(vm, line, param)
	local array = {}
	for i = 1, param do
		local val = vm.pop()
		if type(val) == 'table' then
			for k = 1, #val do table.insert(array, val[k]) end
		else
			table.insert(array, val)
		end
	end
	--Reverse the table so it's in the correct order
	local res = {}
	for i = 1, #array do
		table.insert(res, array[#array - i + 1])
	end
	vm.push(res)
end
