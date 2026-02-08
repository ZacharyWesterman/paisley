return function(vm)
	local v = vm.pop()
	local text, chars = std.str(v[1]), std.str(v[2])

	if chars == nil then
		vm.push(text:match('^%s*(.-)%s*$'))
		return
	end

	-- Remove any of a list of chars
	local pattern = '^[' .. std.str(chars):gsub('(%W)', '%%%1') .. ']*(.-)[' ..
		std.str(chars):gsub('(%W)', '%%%1') .. ']*$'
	vm.push(text:match(pattern))
end
