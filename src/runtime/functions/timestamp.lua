return function(vm)
	local v = vm.pop()[1]
	if type(v) ~= 'table' then
		vm.push(0)
		return
	end
	vm.push((v[1] or 0) * 3600 + (v[2] or 0) * 60 + (v[3] or 0) + (v[4] or 0) / 1000)
end
