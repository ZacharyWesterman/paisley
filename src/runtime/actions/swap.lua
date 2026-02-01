return function(vm, line, p1, p2)
	local v1 = STACK[#STACK]
	local v2 = STACK[#STACK - 1]
	STACK[#STACK - 1] = v1
	STACK[#STACK] = v2
end
