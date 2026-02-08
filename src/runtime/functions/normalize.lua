return function(vm)
	local v = vm.pop()[1]
	if std.type(v) ~= 'array' then
		v = { std.num(v) }
	end
	vm.push(std.normalize(v))
end
