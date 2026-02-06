return function(vm)
	local dt = vm.pop()[1]
	if std.type(dt) ~= 'object' then
		vm.push(0)
		return
	end
	vm.push(os.time {
		year = dt.date and dt.date[3],
		month = dt.date and dt.date[2],
		day = dt.date and dt.date[1],
		hour = dt.time and dt.time[1],
		min = dt.time and dt.time[2],
		sec = dt.time and dt.time[3],
	})
end
