return function(vm, line, p1, p2)
	local keep = {}
	if p1 then
		--Keep the N top elements
		for i = 1, p1 do
			if STACK[#STACK] == NULL then break end
			table.insert(keep, vm.pop())
		end
	end
	while vm.pop() ~= nil do end
	if p1 then
		--Re-push the N top elements
		for i = #keep, 1, -1 do
			vm.push(keep[i])
		end
	end
end
