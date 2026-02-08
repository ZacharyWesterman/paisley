return function(vm)
	local v = vm.pop()
	vm.push(std.str(v[1]):match(std.str(v[2])))
end
