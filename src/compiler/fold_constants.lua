require "src.compiler.functions.fold"

local function number_op(v1, v2, operator)
	if type(v1) == 'table' or type(v2) == 'table' then
		if type(v1) ~= 'table' then v1 = { v1 } end
		if type(v2) ~= 'table' then v2 = { v2 } end

		local result = {}
		for i = 1, math.min(#v1, #v2) do
			table.insert(result, operator(std.num(v1[i]), std.num(v2[i])))
		end
		return result
	else
		return operator(std.num(v1), std.num(v2))
	end
end

---AST: Fold constants
---@param token table
---@param file string?
function FOLD_CONSTANTS(token, file)
	if not token.children then return end

	local operator = token.text
	local c1, c2 = token.children[1], token.children[2]

	---@param token Token
	---@return boolean
	local function not_const(token) return token.value == nil and token.id ~= TOK.lit_null end

	if token.id == TOK.array_concat then
		for i = 1, #token.children do
			local child = token.children[i]
			if child.id == TOK.lit_null or child.type == 'null' then
				parse_error(child.span, 'Arrays cannot contain null elements', file)
			end
		end
	end

	if token.id == TOK.index and c2.unterminated and not_const(c1) then
		c2.value = nil
		return
	end

	--Ternary operators are unique: if the condition is constant, they can be folded
	if token.id == TOK.ternary then
		local child
		local c3 = token.children[3]

		--regardless of whether they're constant, we can deduce the type if both possible results have a type
		if c2.type and c3.type and not token.type then
			if c2.type == c3.type then
				token.type = c2.type
			else
				token.type = _G['TYPE_ANY']
			end
		end

		if not_const(c1) then return end
		if std.bool(c1.value) then child = c2 else child = c3 end

		token.id = child.id
		token.value = child.value
		token.text = child.text
		token.line = child.line
		token.col = child.col
		token.children = child.children
		return
	end

	--List comprehension is also unique: if the expression has the form "i for i in EXPR (no condition)" then can optimize the whole list comprehension away.
	if token.id == TOK.list_comp and c1.id == TOK.variable and c1.text == c2.text and not token.children[4] then
		local child = token.children[3]
		token.id = child.id
		token.value = child.value
		token.text = child.text
		token.line = child.line
		token.col = child.col
		token.children = child.children
		return
	end

	--Even if not const, we can still tell the output type of list comprehension
	if token.id == TOK.list_comp then
		if token.children[1].type then
			token.type = SIGNATURE('array[' .. TYPE_TEXT(token.children[1].type) .. ']')
		else
			token.type = _G['TYPE_ARRAY']
		end
	end

	--Another unique case: the reduce() function takes an operator as the second parameter, not a value
	if token.id == TOK.func_call and token.text == 'reduce' then
		if c1.value then
			if #c1.value == 0 then
				token.id = TOK.lit_null
				token.children = nil
				token.text = tostring(nil)
				return
			end

			operator = c2.text
			local result = c1.value[1]
			for i = 2, #c1.value do
				local v = c1.value[i]
				if operator == '==' then
					result = result == v
				elseif operator == '<' then
					result = std.compare(result, v, function(p1, p2) return p1 < p2 end)
				elseif operator == '<=' then
					result = std.compare(result, v, function(p1, p2) return p1 <= p2 end)
				elseif operator == '>' then
					result = std.compare(result, v, function(p1, p2) return p1 > p2 end)
				elseif operator == '>=' then
					result = std.compare(result, v, function(p1, p2) return p1 >= p2 end)
				elseif operator == '!=' then
					result = result ~= v
				elseif operator == '+' then
					result = std.num(result) + std.num(v)
				elseif operator == '-' then
					result = std.num(result) - std.num(v)
				elseif operator == '*' then
					result = std.num(result) * std.num(v)
				elseif operator == '/' then
					result = std.num(result) / std.num(v)
				elseif operator == '//' then
					result = math.floor(std.num(result) / std.num(v))
				elseif operator == '%' then
					result = std.num(result) % std.num(v)
				elseif operator == '^' then
					result = std.num(result) ^ std.num(v)
				elseif operator == 'and' then
					result = std.bool(result) and std.bool(v)
				elseif operator == 'or' then
					result = std.bool(result) or std.bool(v)
				elseif operator == 'xor' then
					result = (std.bool(result) or std.bool(v)) and not (std.bool(result) and std.bool(v))
				end
				--Ignore any other operators... we only care about binary operators.
			end

			token.value = result
			token.text = tostring(result)
			token.children = nil
		else
			--Even if the parameter is not constant, we can still deduce the output type based on the operator
			if std.arrfind({ '+', '-', '/', '//', '%' }, c2.text, 1) > 0 then
				token.type = 'number'
			elseif std.arrfind({ '==', '<', '<=', '>', '>=', '!=', 'and', 'or', 'xor' }, c2.text, 1) > 0 then
				token.type = 'boolean'
			end
		end
		return
	end

	--Objects must be handled differently: their children will not directly have a value, but must have constant children themselves
	if token.id == TOK.object then
		local value = std.object()
		for i = 1, #token.children do
			local pair = token.children[i]
			--make sure all children are constant
			if not pair.is_constant then return end

			if #pair.children > 0 then
				value[std.str(pair.children[1].value)] = pair.children[2].value
			end
		end

		token.id = TOK.lit_object
		token.value = value
		token.text = '{}'
		token.type = _G['TYPE_OBJECT']
		token.children = {}
		return
	end

	--If this token does not contain only constant children, we cannot fold it.
	for i = 1, #token.children do
		local ch = token.children[i]
		if ch.value == nil and ch.id ~= TOK.lit_null then
			return
		end
	end


	if token.id == TOK.add or token.id == TOK.multiply or token.id == TOK.exponent then
		--Fold the two values into a single value
		local result
		if operator == '+' then
			result = number_op(c1.value, c2.value, function(a, b) return a + b end)
		elseif operator == '-' then
			result = number_op(c1.value, c2.value, function(a, b) return a - b end)
		elseif operator == '*' then
			result = number_op(c1.value, c2.value, function(a, b) return a * b end)
		elseif operator == '/' then
			result = number_op(c1.value, c2.value, function(a, b) return a / b end)
		elseif operator == '//' then
			result = number_op(c1.value, c2.value, function(a, b) return math.floor(c1.value / c2.value) end)
		elseif operator == '%' then
			result = number_op(c1.value, c2.value, function(a, b) return a % b end)
		elseif operator == '^' then
			result = number_op(c1.value, c2.value, function(a, b) return a ^ b end)
		else
			parse_error(token.span, 'COMPILER BUG: No constant folding rule for operator "' .. operator .. '"!', file)
		end

		local r = tostring(result)
		if r == tostring(1 / 0) or r == tostring(0 / 0) or r == tostring(-(0 / 0)) then
			parse_error(token.span, 'Division by zero', file)
		end

		token.value = result
		token.children = nil
		token.text = tostring(result)
		token.id = TOK.lit_number
	elseif token.id == TOK.comparison then
		--Can't fold constants for "match" top-level comparisons
		if not c2 then return end

		local result
		if operator == '==' then
			result = c1.value == c2.value
		elseif operator == '<' then
			result = std.compare(c1.value, c2.value, function(p1, p2) return p1 < p2 end)
		elseif operator == '<=' then
			result = std.compare(c1.value, c2.value, function(p1, p2) return p1 <= p2 end)
		elseif operator == '>' then
			result = std.compare(c1.value, c2.value, function(p1, p2) return p1 > p2 end)
		elseif operator == '>=' then
			result = std.compare(c1.value, c2.value, function(p1, p2) return p1 >= p2 end)
		elseif operator == '!=' then
			result = c1.value ~= c2.value
		else
			parse_error(token.span, 'COMPILER BUG: No constant folding rule for operator "' .. operator .. '"!', file)
		end

		token.value = result
		token.children = nil
		token.text = tostring(result)
		token.id = TOK.lit_boolean
	elseif token.id == TOK.boolean then
		if c2 then --Binary operators
			if operator == 'or' then
				token.value, token.id = std.bool(c1.value) or std.bool(c2.value), TOK.lit_boolean
			elseif operator == 'and' then
				token.value, token.id = std.bool(c1.value) and std.bool(c2.value), TOK.lit_boolean
			elseif operator == 'xor' then
				local v1 = std.bool(c1.value)
				local v2 = std.bool(c2.value)
				token.value, token.id = (v1 or v2) and not (v1 and v2), TOK.lit_boolean
			elseif operator == 'in' then
				local result = false
				if c2.id == TOK.lit_array then
					local i
					for i = 1, #c2.value do
						if c2.value[i] == c1.value then
							result = true
							break
						end
					end
				elseif c2.id == TOK.lit_object then
					result = c2.value[std.str(c1.value)] ~= nil
				else
					result = std.contains(std.str(c2.value), std.str(c1.value))
				end

				token.value = result
				token.id = TOK.lit_boolean
			elseif operator == 'like' then
				local v1 = std.str(c1.value)
				local v2 = std.str(c2.value)
				token.value, token.id = v1:match(v2) ~= nil, TOK.lit_boolean
			else
				parse_error(token.span, 'COMPILER BUG: No constant folding rule for operator "' .. operator .. '"!', file)
			end
			token.children = nil
			token.text = tostring(token.value)
		elseif operator ~= 'exists' then --Unary operators (just "not")
			if c1.value ~= nil or c1.id == TOK.lit_null then
				token.value = not c1.value or c1.value == 0 or c1.value == ''
				token.id = TOK.lit_boolean
				token.children = nil
				token.text = tostring(token.value)
			elseif c1.id == TOK.boolean and c1.text == 'not' then
				--Fold redundant "not" operators
				local ch = c1.children[1]
				token.id, token.text, token.value, token.children = ch.id, ch.text, ch.value, ch.children
			end
		end
	elseif token.id == TOK.length then
		if c1.value ~= nil or c1.id == TOK.lit_null and (not c1.children or #c1.children == 0) then
			if type(c1.value) ~= 'string' and type(c1.value) ~= 'table' then
				parse_error(token.span, 'Length operator can only operate on strings and arrays', file)
			end

			token.id = TOK.lit_number
			token.value = #c1.value
			token.text = tostring(token.value)
			token.children = nil
		end
	elseif token.id == TOK.func_call then
		if FUNC_OPERATIONS[token.text] then
			--Build list of parameters
			local values = {}
			for i = 1, #token.children do
				table.insert(values, token.children[i].value)
			end

			--Run functions to get resultant value
			local fn = FUNC_OPERATIONS[token.text]
			local param_ct = BUILTIN_FUNCS[token.text]
			if param_ct < 0 then
				token.value = fn(values, token, file)
			elseif param_ct == 0 then
				token.value = fn(token, file)
			else
				if #values == 0 then
					token.value = fn(nil, token, file)
				else
					local u = table.unpack
					---@diagnostic disable-next-line
					if not u then u = unpack end

					table.insert(values, token)
					table.insert(values, file)
					token.value = fn(u(values))
				end
			end

			--Fold values of only the deterministic functions
			if token.value ~= nil then
				token.text = tostring(token.value)
				local tp = std.deep_type(token.value)
				if tp == 'boolean' then
					token.id = TOK.lit_boolean
				elseif tp == 'number' then
					token.id = TOK.lit_number
				elseif tp == 'string' then
					token.id = TOK.string_open
				elseif tp:sub(1, 5) == 'array' then
					token.id = TOK.lit_array
					token.text = '[]'
					token.type = SIGNATURE(tp)
				elseif tp:sub(1, 6) == 'object' then
					token.id = TOK.lit_object
					token.text = '{}'
					token.type = SIGNATURE(tp)
				else
					parse_error(token.span,
						'COMPILER BUG: Folding of function "' .. token.text .. '" resulted in data of type "' .. tp ..
						'"!', file)
				end
				token.children = nil
			end
		elseif math[token.text] then
			local val = math[token.text](c1.value)

			--Check for NaN
			local r = tostring(val)
			if r == tostring(1 / 0) or r == tostring(0 / 0) or r == tostring(-(0 / 0)) then
				parse_error(token.span, 'Result of "' .. token.text .. '(' .. c1.value .. ')" is not a number', file)
			end

			token.id, token.value, token.text, token.children = TOK.lit_number, val, tostring(val), nil
		end
	elseif token.id == TOK.array_concat then
		token.id = TOK.lit_array
		token.text = '[]'
		token.value = std.array()
		for i = 1, #token.children do
			--If a slice operator is nested in an array_concat operation, merge the arrays
			if token.children[i].reduce_array_concat then
				local k
				for k = 1, #token.children[i].value do
					table.insert(token.value --[[@as table]], token.children[i].value[k])
				end
			else
				table.insert(token.value --[[@as table]], token.children[i].value)
			end
		end
		token.type = SIGNATURE(std.deep_type(token.value))
		token.children = nil
	elseif token.id == TOK.array_slice then
		token.type = _G['TYPE_ARRAY_NUMBER']
		if #token.children == 1 then
			if not token.unterminated then
				parse_error(token.span,
					'Unterminated slices can only be used when indexing an array or string, e.g. `value[begin_index:]`, and must be the only expression inside the brackets',
					file)
			end
			token.value = c1.value
			return
		end

		local start, stop = token.children[1].value, token.children[2].value

		--For the sake of output bytecode size, don't fold if the array slice is too large!
		if (stop - start) <= 20 then
			token.id = TOK.lit_array
			token.text = '[]'
			token.value = {}
			for i = start, stop do
				table.insert(token.value --[[@as table]], i)
			end
			token.children = nil
			token.reduce_array_concat = true --If a slice operator is nested in an array_concat operation, merge the arrays
		elseif stop - start >= std.MAX_ARRAY_LEN then
			local msg = 'Attempt to create an array of ' ..
				(stop - start + 1) .. ' elements (max is ' .. std.MAX_ARRAY_LEN .. '). Array truncated.'
			--[[minify-delete]]
			if _G['LANGUAGE_SERVER'] then
				INFO.warning(token.span, msg, file)
			else
				--[[/minify-delete]]
				msg = token.span.from.line .. ', ' .. token.span.from.col .. ': ' .. msg
				if file then msg = file .. ': ' .. msg end
				print('WARNING: ' .. msg)
				--[[minify-delete]]
			end
			--[[/minify-delete]]

			--We KNOW the array will be to large, so truncate it.
			token.children[2].value = std.MAX_ARRAY_LEN + start - 1
		end
	elseif token.id == TOK.negate then
		token.id = TOK.lit_number
		token.value = number_op(0, c1.value, function(a, b) return a - b end)
		token.text = tostring(token.value)
		token.children = nil
	elseif token.id == TOK.concat then
		token.id = TOK.string_open
		token.value = std.str(c1.value) .. std.str(c2.value)
		token.text = token.value
		token.children = nil
	elseif token.id == TOK.string_open then
		token.value = ''
		local i
		for i = 1, #token.children do
			token.value = token.value .. std.str(token.children[i].value)
		end
		token.children = nil
	elseif token.id == TOK.index then
		local val = c1.value
		local is_string = false
		if type(val) == 'string' then
			is_string = true
			val = std.split(val, '')
		elseif type(val) ~= 'table' then
			parse_error(token.span, 'Cannot get subset of a value of type "' .. std.type(val) .. '"', file)
		end

		if c2.unterminated then
			--can only happen if this is a non-terminated array slice
			--in this case, slice is from the start pos to the full length of this token value.
			local result = {}
			for i = c2.value, #val do
				table.insert(result, i)
			end
			c2.value = result
		end

		local result
		if type(c2.value) == 'table' then
			local i
			result = {}
			for i = 1, #c2.value do
				local ix = c2.value[i]
				if type(ix) ~= 'number' and std.type(val):sub(1, 6) ~= 'object' then
					parse_error(token.span, 'Cannot use a non-number value as an array index', file)
				end

				if std.type(val) ~= 'object' then
					if ix < 0 then
					elseif ix == 0 then
						parse_error(token.span, 'Indexes start at 1, not 0', file)
					end
				end
				table.insert(result, val[ix])
			end

			if is_string then
				token.text = '"'
				result = std.join(result, '')
				token.id = TOK.string_open
			else
				token.text = '[]'
				token.id = TOK.lit_array
			end
		elseif type(c2.value) ~= 'number' and std.type(val) ~= 'object' then
			parse_error(token.span, 'Cannot use a non-number value as an array index', file)
		else
			local ix = c2.value
			if type(ix) == 'number' then
				if ix < 0 and std.type(val) ~= 'object' then
					---@diagnostic disable-next-line
					ix = #val + ix + 1
				elseif ix == 0 then
					parse_error(token.span, 'Indexes start at 1, not 0', file)
				end
			end
			if std.type(val) == 'object' then result = val[std.str(ix)] else result = val[ix] end
			token.text = std.debug_str(result)
			if type(result) == 'string' then token.text = '"' end
		end

		token.value = result
		token.type = std.deep_type(result)
		token.children = nil

		local rs = {
			string = TOK.string_open,
			array = TOK.text,
			null = TOK.lit_null,
			boolean = TOK.lit_boolean,
			number = TOK.lit_number,
			object = TOK.lit_object,
		}
		token.id = rs[token.type]
	elseif token.id == TOK.key_value_pair then
		token.is_constant = true
	else
		parse_error(token.span, 'COMPILER BUG: No constant folding rule for token id "' .. token_text(token.id) .. '"!',
			file)
	end
end
