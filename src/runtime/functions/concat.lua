return function(vm, line, param)
	local result = ''
	while param > 0 do
		result = std.str(vm.pop()) .. result
		param = param - 1
	end
	vm.push(result)
end
