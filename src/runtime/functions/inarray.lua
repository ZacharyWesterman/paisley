return function(vm)
	local data, val = vm.pop(), vm.pop()
	local result = false
	if std.type(data) == 'array' then
		for i = 1, #data do
			if data[i] == val then
				result = true
				break
			end
		end
	elseif std.type(data) == 'object' then
		result = data[std.str(val)] ~= nil
	else
		result = std.contains(std.str(data), val)
	end
	vm.push(result)
end
