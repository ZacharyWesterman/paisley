return function(vm)
	local v = vm.pop()[1]
	if type(v) == 'string' then
		vm.push(v:reverse())
		return
	elseif type(v) ~= 'table' then
		vm.push({ v })
		return
	end

	local result = {}
	for i = #v, 1, -1 do
		table.insert(result, v[i])
	end

	vm.push(result)
end
