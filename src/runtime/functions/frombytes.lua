return function(vm)
	local v = vm.pop()
	if type(v[1]) ~= 'table' then
		vm.push(0)
	else
		local result = 0
		for i = 1, #v[1] do
			result = result * 256 + v[1][i]
		end
		vm.push(result)
	end
end
