return function(vm)
	local v = vm.pop()
	if type(v[1]) ~= 'table' then
		vm.push(v[1])
	else
		vm.push(v[1][math.random(1, #v[1])])
	end
end
