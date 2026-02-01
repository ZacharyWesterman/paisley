return function(vm, line, p1, p2)
	local value = vm.pop()
	local index = vm.pop()

	---@type string
	local var_name = vm.pop()

	local var = VARS[var_name]
	if type(var) == 'string' then
		index = std.num(index)
		return
	elseif type(var) ~= 'table' then
		print('WARNING: attempted to index a non-iterable variable "' .. var_name .. '", ignoring!')
		return
	end

	if index == nil then
		--If no index is given, append to array or do nothing if object
		if std.type(var) == 'array' then
			table.insert(var, value)
		else
			print('WARNING: attempted to append to a non-array variable "' .. var_name .. '", ignoring!')
		end
		return
	end

	std.update_element(var, index, value)
end
