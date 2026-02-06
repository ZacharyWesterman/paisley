return function(vm)
	local v = vm.pop()
	local str_value, base = std.str(v[1]), std.num(v[2])
	if base < 2 or base > 36 then
		error('Error: from_base() base must be between 2 and 36!')
		return
	end
	vm.push(std.from_base(str_value, base))
end
