return function(vm)
	local num = math.floor(std.num(vm.pop()[1]))

	local nans = {
		['nan'] = true,
		['inf'] = true,
		['-inf'] = true,
	}

	if nans[tostring(num)] then num = 0 end
	vm.push(string.char(num % 256))
end
