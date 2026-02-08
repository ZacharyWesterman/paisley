return function(vm)
	local v = vm.pop()
	local base, value = v[2], std.num(v[1])
	if base ~= nil then
		base = std.num(base)
		if base <= 1 then
			error('Error: log() base must be greater than 1!')
			return
		end
	end

	vm.push(math.log(value, base))
end
