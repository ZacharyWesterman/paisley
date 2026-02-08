return function(vm)
	local v = vm.pop()
	local res
	if type(v[1]) == 'table' then
		res = std.arrfind(v[1], v[2], std.num(v[3]))
	else
		res = std.strfind(std.str(v[1]), std.str(v[2]), std.num(v[3]))
	end
	vm.push(res)
end
