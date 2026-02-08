return function(vm)
	vm.push(std.hash(std.str(vm.pop()[1])))
end
