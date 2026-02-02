return function(vm)
	local v, target = vm.pop()

	for i = 1, #v do
		if type(v[i]) == 'table' then
			for k = 1, #v[i] do
				if target then target = math.max(target, std.num(v[i][k])) else target = std.num(v[i][k]) end
			end
		else
			if target then target = math.max(target, std.num(v[i])) else target = std.num(v[i]) end
		end
	end
	vm.push(target)
end
