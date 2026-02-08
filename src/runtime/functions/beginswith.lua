return function(vm)
	local v = vm.pop()
	local search, substring = std.str(v[1]), std.str(v[2])
	vm.push(search:sub(1, #substring) == substring)
end
