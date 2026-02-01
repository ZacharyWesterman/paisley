return function(vm, line, p1, p2)
	local value = vm.pop()
	if type(value) ~= 'table' then value = { value } end

	for i = 1, #p1 do
		local v = value[i]
		if v == nil then v = NULL end
		VARS[p1[i]] = v
	end
end
