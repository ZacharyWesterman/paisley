return function(vm)
	local v = vm.pop()
	local array1, index1, index2, array2 = v[1], std.num(v[2]), std.num(v[3]), v[4]
	local result = std.array()

	if type(array1) ~= 'table' then array1 = { array1 } end
	if type(array2) ~= 'table' then array2 = { array2 } end

	for i = 1, index1 - 1 do table.insert(result, array1[i]) end
	for i = 1, #array2 do table.insert(result, array2[i]) end
	for i = index2 + 1, #array1 do table.insert(result, array1[i]) end
	vm.push(result)
end
