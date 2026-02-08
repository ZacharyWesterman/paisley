return function(vm)
	local v = vm.pop()
	local b, a = v[1], v[2]
	local t1, t2 = type(a), type(b)
	local result

	if t1 ~= 'table' and t2 == 'table' then
		b = b[1]
	elseif t1 == 'table' and t2 ~= 'table' then
		a = a[1]
	end

	if t1 == 'table' then
		local total = 0
		for i = 1, math.min(#a, #b) do
			local p = a[i] - b[i]
			total = total + p * p
		end
		result = math.sqrt(total)
	else
		result = math.abs(b - a)
	end
	vm.push(result)
end
