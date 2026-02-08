return function(vm)
	local v = vm.pop()
	if type(v[1]) == 'table' then
		table.insert(v[1], v[2])
		vm.push(v[1])
	else
		vm.push({ v[1], v[2] })
	end
end
