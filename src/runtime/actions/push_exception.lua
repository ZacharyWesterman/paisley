return function(vm, line, p1, p2)
	--Build the exception object to handle or throw later.
	local err = std.object()
	err.message = p1[1]
	err.stack = { line }
	err.type = p1[2]
	err.file = FILE
	err.line = line

	vm.push(err)
end
