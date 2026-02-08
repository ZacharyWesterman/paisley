return function(vm)
	local v = vm.pop()
	local text = std.str(v[1])
	local character = std.str(v[2]):sub(1, 1)
	local width = std.num(v[3])

	vm.push(character:rep(width - #text) .. text)
end
