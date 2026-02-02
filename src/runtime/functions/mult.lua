return function(vm)
	local v, total = vm.pop(), 1
	for i = 1, #v do
		if type(v[i]) == 'table' then
			for k = 1, #v[i] do
				total = total * std.num(v[i][k])
				if total == 0 then break end
			end
		else
			total = total * std.num(v[i])
		end
		if total == 0 then break end
	end
	vm.push(total)
end
