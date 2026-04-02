return function(args, info, json)
	if #args > 0 then
		info('Expected 0 arguments, but got ' .. #args .. '.')
	end
end
