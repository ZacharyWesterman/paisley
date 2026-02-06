return function(vm)
	local timestamp = vm.pop()[1]
	local datetime = std.object()
	if std.type(timestamp) ~= 'number' then
		vm.push(datetime)
		return
	end
	local dt = os.date('*t', timestamp)
	datetime.date = { dt.day, dt.month, dt.year }
	datetime.time = { dt.hour, dt.min, dt.sec }
	vm.push(datetime)
end
