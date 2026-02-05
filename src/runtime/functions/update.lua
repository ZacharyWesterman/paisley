return function(vm)
	local v = vm.pop()
	local object, indices, value = v[1], v[2], v[3]

	vm.push(std.update_element(object, indices, value))
end
