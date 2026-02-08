return function(vm)
	local v = vm.pop()
	if type(v[1]) ~= 'table' then v[1] = { v[1] } end
	local n = std.num(v[2])

	local meta = getmetatable(v[1])
	if not meta or meta.is_array then
		--If index is negative, insert starting at the end
		if n < 0 then n = #v[1] + n + 2 end

		if n > #v[1] then
			table.insert(v[1], v[3])
		elseif n > 0 then
			table.insert(v[1], n, v[3])
		else
			--Insert at beginning if index is less than 1
			table.insert(v[1], 1, v[3])
		end
	end
	vm.push(v[1])
end
