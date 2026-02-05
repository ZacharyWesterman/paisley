return function(vm)
	local v = vm.pop()[1]
	if type(v) == 'table' then
		vm.push(std.unique(v))
	else
		vm.push { v }
	end
end
