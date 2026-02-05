return function(vm)
	vm.push(std.b64_encode(std.str(vm.pop()[1])))
end
