return function(vm)
	local v = vm.pop()
	local res
	if type(v[1]) == 'table' then
		res = std.arrfind(v[1], v[2], 1)
	else
		res = std.strfind(std.str(v[1]), std.str(v[2]), 1)
	end
	vm.push(res)
end
