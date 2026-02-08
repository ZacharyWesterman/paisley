return function(vm)
	local is_table, v = false, vm.pop()[1]
	if type(v) ~= 'table' then
		vm.push({ v })
		return
	end

	for key, val in pairs(v) do
		if type(val) == 'table' then
			is_table = true
			break
		end
	end

	if is_table then
		table.sort(v, function(a, b) return std.str(a) < std.str(b) end)
	else
		table.sort(v)
	end
	vm.push(v)
end
