return function(vm)
	local function flatten(array, depth)
		local result = std.array()
		for i = 1, #array do
			if depth > 0 and type(array[i]) == 'table' then
				local flat = flatten(array[i], depth - 1)
				for k = 1, #flat do table.insert(result, flat[k]) end
			else
				table.insert(result, array[i])
			end
		end
		return result
	end

	local v = vm.pop()
	if type(v[1]) ~= 'table' then
		vm.push({ v[1] })
		return
	end

	vm.push(flatten(v[1], v[2] and std.num(v[2]) or math.maxinteger))
end
