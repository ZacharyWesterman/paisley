return function(vm)
	local v = vm.pop()[1]
	if type(v) ~= 'table' then
		v = std.num(v)
		local result = {
			math.floor(v / 3600),
			math.floor(v / 60) % 60,
			math.floor(v) % 60,
		}
		local millis = math.floor(v * 1000) % 1000
		if millis ~= 0 then result[4] = millis end
		v = result
	end
	local result = ''
	for i = 1, #v do
		if i > 3 then
			result = result .. '.'
		elseif #result > 0 then
			result = result .. ':'
		end
		local val = tostring(std.num(v[i]))
		result = result .. ('0'):rep(2 - #val) .. val
	end
	vm.push(result)
end
