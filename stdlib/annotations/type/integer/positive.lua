return function(args, info)
	for _, arg in ipairs(args) do
		info(arg.type:tostring())
		--@param type annotations should already make sure that this is a number.
		if arg.type and arg.type:is_superset_of('number') then
			if arg.value ~= nil and (arg.value <= 0 or math.floor(arg.value) ~= arg.value) then
				arg:info('Expected a positive integer, but got `' .. arg.value .. '`.')
			end
		end
	end
end
