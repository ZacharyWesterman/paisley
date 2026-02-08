return function(vm, line, p1, p2)
	local v = vm.pop()
	if v == nil then
		VARS[p1] = NULL
	else
		VARS[p1] = v
	end
end
