return function(vm)
	local v = vm.pop()[1]
	if type(v) ~= 'table' then v = { v } end
	local result = ''
	for i = #v, 1, -1 do
		if #result > 0 then result = result .. '-' end
		local val = tostring(std.num(v[i]))
		result = result .. ('0'):rep(2 - #val) .. val
	end
	vm.push(result)
end
