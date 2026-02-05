return function(vm)
	local v = vm.pop()
	local array = std.array()
	for i in std.str(v[1]):gmatch(std.str(v[2])) do
		table.insert(array, i)
	end
	vm.push(array)
end
