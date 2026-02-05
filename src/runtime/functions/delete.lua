return function(vm)
	local v = vm.pop()
	if type(v[1]) ~= 'table' then v[1] = { v[1] } end
	table.remove(v[1], std.num(v[2]))
	vm.push(v[1])
end
