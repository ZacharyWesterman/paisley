local function validate_expression(span, filename, expr)

end

return {
	validate = function(span, filename, op, args)
		if op == 'if' or op == 'elif' then
			return validate_expression(span, filename, args)
		elseif op == 'else' or op == 'end' then
			if #args > 0 then
				parse_error(span, 'Compiler directive `$' .. op .. '` does not take arguments', filename)
				return false
			end
		else
			local msg = 'Unknown compiler directive `$' .. op .. '`. '
			msg = msg .. 'Valid directives are `$if`, `$elif`, `$else`, or `$end`'
			parse_error(span, msg, filename)
			return false
		end

		return true
	end,
}
