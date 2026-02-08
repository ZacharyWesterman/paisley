return function(vm)
	local v = vm.pop()
	local res
	if type(v[1]) == 'table' then
		res = std.arrcount(v[1], v[2])
	else
		res = std.strcount(std.str(v[1]), std.str(v[2]))
	end
	vm.push(res)
end
