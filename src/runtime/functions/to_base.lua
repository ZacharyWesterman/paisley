return function(vm)
	local v = vm.pop()
	local number, base, pad_width = std.num(v[1]), std.num(v[2]), std.num(v[3])
	vm.push(std.to_base(number, base, pad_width))
end
