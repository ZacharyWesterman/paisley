local function is_version(text)
	return tostring(text):match('%d+(%.%d+)*')
end

local function version_compare(lhs, rhs)
	local left, right = tostring(lhs):gmatch('%d+'), tostring(rhs):gmatch('%d+')
	while true do
		local lval, rval = left(), right()
		if not lval and not rval then break end

		local l, r = tonumber(lval or 0), tonumber(rval or 0)
		if l < r then return -1 end
		if l > r then return 1 end
	end
	return 0
end

local function validate_expression(dir, filename, get_token)
	local stack = {}
	local op_stack = {}

	local flags = {
		['version'] = function(span)
			--[[minify-delete]]
			if _G['LANGUAGE_SERVER'] then
				local msg = '**version** = ' .. _G['VERSION']
				msg = msg .. '\nThe Paisley version at compile time.'
				msg = msg .. '\nCompare with version numbers like `X.Y.Z`.'
				INFO.hint(span, msg, filename)
				INFO.constant(span, filename)
			end
			--[[/minify-delete]]

			return _G['VERSION']
		end,
		['build'] = function(span)
			local build

			--[[minify-delete]]
			if _G['RESTRICT_TO_PLASMA_BUILD'] then
				--[[/minify-delete]]
				build = 'plasma'
				--[[minify-delete]]
			else
				build = 'desktop'
			end
			--[[/minify-delete]]

			--[[minify-delete]]
			if _G['LANGUAGE_SERVER'] then
				local msg = '**build** = ' .. build
				msg = msg .. '\nThe build type at compile time.'
				msg = msg .. '\nCurrently, the only possible values are `plasma` or `desktop`.'
				INFO.hint(span, msg, filename)
				INFO.constant(span, filename)
			end
			--[[/minify-delete]]

			return build
		end,
		['target'] = function(span)
			local target
			--[[minify-delete]]
			if _G['RESTRICT_TO_PLASMA_BUILD'] then
				--[[/minify-delete]]
				target = 'lua'
				--[[minify-delete]]
			else
				target = _G['TARGET']
			end
			--[[/minify-delete]]

			--[[minify-delete]]
			if _G['LANGUAGE_SERVER'] then
				local msg = '**target** = ' .. target
				msg = msg .. '\nThe compilation target.'
				msg = msg .. '\nPossible values are `lua`, `c` or `cpp`.'
				INFO.hint(span, msg, filename)
				INFO.constant(span, filename)
			end
			--[[/minify-delete]]

			return target
		end,
	}

	local ops = {
		['or']  = {
			prec = 1,
			oper = function(lhs, rhs) return lhs or rhs end,
		},
		['and'] = {
			prec = 1,
			oper = function(lhs, rhs) return lhs and rhs end,
		},
		['!=']  = {
			prec = 2,
			oper = function(lhs, rhs) return lhs ~= rhs end,
		},
		['=']   = {
			prec = 2,
			oper = function(lhs, rhs) return lhs == rhs end,
		},
		['>']   = {
			prec = 2,
			oper = function(lhs, rhs)
				--Compare as version numbers
				if is_version(lhs) or is_version(rhs) then
					return version_compare(lhs, rhs) > 0
				end

				--Compare as text.
				return lhs > rhs
			end,
		},
		['>=']  = {
			prec = 2,
			oper = function(lhs, rhs)
				--Compare as version numbers
				if is_version(lhs) or is_version(rhs) then
					return version_compare(lhs, rhs) >= 0
				end

				--Compare as text.
				return lhs >= rhs
			end,
		},
		['<']   = {
			prec = 2,
			oper = function(lhs, rhs)
				--Compare as version numbers
				if is_version(lhs) or is_version(rhs) then
					return version_compare(lhs, rhs) < 0
				end

				--Compare as text.
				return lhs < rhs
			end,
		},
		['<=']  = {
			prec = 2,
			oper = function(lhs, rhs)
				--Compare as version numbers
				if is_version(lhs) or is_version(rhs) then
					return version_compare(lhs, rhs) <= 0
				end

				--Compare as text.
				return lhs <= rhs
			end,
		},
	}

	--[[
	Convert infix expression to postfix for easier evaluation.
	--]]
	for token in get_token do
		if token.text == '(' then
			--If '(', push to stack
			table.insert(op_stack, token)
		elseif token.text == ')' then
			--If ')', pop until '('
			while #op_stack > 0 and op_stack[#op_stack].text ~= '(' do
				table.insert(stack, table.remove(op_stack))
			end
			table.remove(op_stack)
		elseif not ops[token.text] then
			--If an operand, add to result
			table.insert(stack, token)
		else
			--If operator
			while #op_stack > 0 and op_stack[#op_stack].text ~= '(' and
				ops[op_stack[#op_stack].text].prec >= ops[token.text].prec
			do
				table.insert(stack, table.remove(op_stack))
			end
			table.insert(op_stack, token)
		end
	end

	-- Push operators to the stack
	while #op_stack > 0 do
		table.insert(stack, table.remove(op_stack))
	end

	--[[
	Evaluate the expression
	--]]
	local result = {}
	for _, token in ipairs(stack) do
		if not ops[token.text] then
			table.insert(result, token)
		else
			local rhs, lhs = table.remove(result), table.remove(result)
			if not lhs or not rhs then
				local msg = 'Syntax error in compiler directive.'
				parse_error(token.span, msg, filename)
				return
			end

			if flags[lhs.text] then lhs = { text = flags[lhs.text](lhs.span) } end

			local val = ops[token.text].oper(lhs.text, rhs.text)
			table.insert(result, val)
		end
	end

	if #result ~= 1 then
		local msg = 'Syntax error in compiler directive.'
		parse_error(dir.span, msg, filename)
		return
	end

	return result[1]
end

local function no_args(dir, filename, get_token)
	local token = get_token()
	if token then
		local msg = 'Compiler directive `$' .. dir.text .. '` takes no arguments, but found `' .. token.text .. '`.'
		parse_error(token.span, msg, filename)
		return
	end
end

local dir = {
	['if'] = validate_expression,
	['elif'] = validate_expression,
	['else'] = no_args,
	['end'] = no_args,
}

return {
	compile = function(text, line, col, filename)
		local span = Span:new(line, col, line, col + #text - 2)

		local function tokenizer(text)
			text = text:gsub('[$\n;]', '')
			return function()
				if #text == 0 then return end

				local match

				--Remove leading whitespace
				match = text:match('^%s+')
				if match then
					text = text:sub(#match + 1, #text)
					col = col + #match
				end

				match = text:match('^[()]')
				if not match then
					match = text:match('^[^()%s]+')
				end

				if match then
					text = text:sub(#match + 1, #text)
					local token = {
						text = match,
						span = Span:new(
							line,
							col,
							line,
							col + #match
						),
					}
					col = col + #match
					return token
				end
			end
		end

		local get = tokenizer(text)
		local directive = get()

		if not directive then
			parse_error(span, 'Expected a compiler directive, but none found.', filename)
			return
		end

		if not dir[directive.text] then
			local msg = 'Unknown compiler directive `$' .. directive.text .. '`. '
			msg = msg .. 'Valid directives are `$if`, `$elif`, `$else` and `$end`.'
			parse_error(directive.span, msg, filename)
			return
		end

		return directive.text, dir[directive.text](directive, filename, get)
	end,
}
