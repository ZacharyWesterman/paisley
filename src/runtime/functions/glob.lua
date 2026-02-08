return function(vm)
	local v = vm.pop()
	local pattern = std.str(v[1])
	local result = std.array()

	for i = 2, #v do
		if std.type(v[i]) == 'array' then
			for k = 1, #v[i] do
				local val = pattern:gsub("%*", std.str(v[i][k]))
				table.insert(result, val)
			end
		else
			local val = pattern:gsub("%*", std.str(v[i]))
			table.insert(result, val)
		end
	end

	vm.push(result)
end
