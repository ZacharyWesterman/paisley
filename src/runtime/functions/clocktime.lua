return function(vm)
	local v = std.num(vm.pop()[1])
	local result = {
		math.floor(v / 3600),
		math.floor(v / 60) % 60,
		math.floor(v) % 60,
	}
	local millis = math.floor(v * 1000) % 1000
	if millis ~= 0 then result[4] = millis end
	vm.push(result)
end
