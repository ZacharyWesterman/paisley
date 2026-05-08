return function(args)
	for _, arg in ipairs(args) do
		--@param type annotations should already make sure that this is a number.
		if arg.type and arg.type:is_superset_of('number') then
			if arg.value ~= nil and math.floor(arg.value) ~= arg.value then
				arg:info('Expected an integer, but got `' .. arg.value .. '`.')
			end
		end
	end
end
