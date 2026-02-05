return function(vm)
	local result, v = {}, vm.pop()
	if type(v[1]) == 'table' and type(v[2]) == 'table' then
		local length = math.min(#v[1], #v[2])
		for i = 1, length do
			table.insert(result, v[1][i])
			table.insert(result, v[2][i])
		end
		for i = length + 1, #v[1] do table.insert(result, v[1][i]) end
		for i = length + 1, #v[2] do table.insert(result, v[2][i]) end
	elseif type(v[1]) == 'table' then
		result = v[1]
	elseif type(v[2]) == 'table' then
		result = v[2]
	end
	vm.push(result)
end
