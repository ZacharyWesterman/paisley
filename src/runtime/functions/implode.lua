return function(vm, line, param)
	--Reverse the table so it's in the correct order
	local res = {}
	for i = param, 1, -1 do
		res[i] = vm.pop()
	end
	vm.push(res)
end
