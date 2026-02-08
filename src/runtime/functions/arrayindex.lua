return function(vm, line)
	local index, data = vm.pop(), vm.pop()
	local is_string = false
	if type(data) ~= 'table' then
		is_string = true
		data = std.split(std.str(data), '')
	end
	local meta = getmetatable(data)
	local is_array = true
	if meta and not meta.is_array then is_array = false end

	local result
	if type(index) ~= 'table' then
		if is_array then
			if type(index) ~= 'number' and not tonumber(index) then
				print('WARNING: line ' .. line .. ': Attempt to index array with non-numeric value, null returned')
				vm.push(NULL)
				return
			end

			index = std.num(index)
			if index < 0 then
				index = #data + index + 1
			elseif index == 0 then
				print('WARNING: line ' .. line .. ': Indexes begin at 1, not 0')
			end

			result = data[index]
		else
			result = data[std.str(index)]
		end
	else
		result = {}
		for i = 1, #index do
			if is_array then
				if type(index[i]) ~= 'number' and not tonumber(index[i]) then
					print('WARNING: line ' ..
						line .. ': Attempt to index array with non-numeric value, null returned')
					vm.push(NULL)
					return
				end

				local ix = std.num(index[i])
				if ix < 0 then
					ix = #data + ix + 1
				elseif ix == 0 then
					print('WARNING: line ' .. line .. ': Indexes begin at 1, not 0')
				end
				table.insert(result, data[ix])
			else
				table.insert(result, data[std.str(index[i])])
			end
		end
		if is_string then result = std.join(result, '') end
	end
	vm.push(result)
end
