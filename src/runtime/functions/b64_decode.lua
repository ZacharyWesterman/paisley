return function(vm)
	vm.push(std.b64_decode(std.str(vm.pop()[1])))
end
