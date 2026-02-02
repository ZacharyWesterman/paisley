return function(vm)
	local v, total = vm.pop(), 0
	for i = 1, #v do
		if type(v[i]) == 'table' then
			for k = 1, #v[i] do total = total + std.num(v[i][k]) end
		else
			total = total + std.num(v[i])
		end
	end
	vm.push(total)
end
