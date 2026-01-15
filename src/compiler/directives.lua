return {
	validate = function(span, filename, op, args)
		if op == 'if' or op == 'elif' then

		elseif op == 'else' or op == 'end' then

		else
			parse_error(span, 'Unknown compiler directive `$' .. op .. '`', filename)
			return false
		end

		return true
	end,
}
