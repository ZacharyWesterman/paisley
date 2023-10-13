func_param_types = {
	mean = {'number'},
	sum = {'number'},
	mult = {'number'},
	min = {'number'},
	max = {'number'},
	clamp = {'number'},
	lerp = {'number'},
	pow = {'number'},
	worddiff = {'string'},
	irandom = {'number'},
	frandom = {'number'},
	split = {'string'},
	join = {'array', 'string'},
}

func_operations = {
	mean = function(values) return func_operators.sum(values) / #values end,
	sum = function(values)
		local total, i = 0, nil
		for i = 1, #values do
			total = total + values[i]
		end
		return total
	end,
	mult = function(values)
		local total, i = 1, nil
		for i = 1, #values do
			total = total * values[i]
		end
		return total
	end,
	min = function(values)
		local least, i = values[1], nil
		for i = 2, #values do least = math.min(least, values[i]) end
		return least
	end,
	max = function(values)
		local most, i = values[1], nil
		for i = 2, #values do most = math.max(most, values[i]) end
		return most
	end,
	clamp = function(min, max, value) return math.min(max, math.max(min, value)) end,
	lerp = function(a, b, x) return a + x * (b - a) end,
	pow = function(a, b) return math.pow(a, b) end,
	boolean = function(data) return std.bool(data) end,
	string = function(data) return std.str(data) end,
	number = function(data) return std.num(data) end,
	array = function(values) return values end, --Interesting short-cut due to compiler quirks!
	worddiff = function(a, b, token, file)
		if type(a) ~= 'string' or type(b) ~= 'string' then
			parse_error(token.line, token.col, 'Function "worddiff(a,b)" expected (string, string) but got ('..std.type(a)..', '..std.type(b)..')', file)
		end

		return lev(a, b)
	end,
	irandom = function(a, b) end,
	frandom = function(a, b) end,
	split = function(a, b) return std.split(a, b) end,
	join = function(a, b) return std.join(a, b) end,
	type = function(a) return std.type(a) end,
	dist = function(a, b, token, file)
		if type(a) ~= 'number' and type(b) ~= 'number' and type(a) ~= 'table' and type(b) ~= 'table' then
			parse_error(token.line, token.col, 'Function "dist(a,b)" expected (number, number) or (array, array) but got ('..std.type(a)..', '..std.type(b)..')', file)
		end

		if type(a) ~= type(b) then
			parse_error(token.line, token.col, 'Function "dist(a,b)" expected (number, number) or (array, array) but got ('..std.type(a)..', '..std.type(b)..')', file)
		end

		if type(a) == 'number' then
			return math.abs(b - a)
		end

		if #a ~= #b then
			parse_error(token.line, token.col, 'Function "dist(a,b)" expected arrays of equal length, got lengths '..#a..' and '..#b, file)
		end

		local total, i = 0
		for i = 1, #a do
			local p = a[i] - b[i]
			total = total + p*p
		end
		return math.sqrt(total)
	end,
}

function fold_constants(token)
	if not token.children then return end

	local operator = token.text
	local c1, c2 = token.children[1], token.children[2]

	--If this token does not contain only constant children, we cannot fold it.
	local i
	for i = 1, #token.children do
		local ch = token.children[i]
		if not ch.value and ch.id ~= tok.lit_null then
			return
		end
	end

	--Cast boolean token to integer
	local function btoi(t)
		if t.id == tok.lit_boolean then
			t.id = tok.lit_number
			if t.text == 'true' then t.value = 1 else t.value = 0 end
		end
	end


	if token.id == tok.add or token.id == tok.multiply then
		--Fold the two values into a single value
		local result
		if operator == '+' then result = c1.value + c2.value
		elseif operator == '-' then result = c1.value - c2.value
		elseif operator == '*' then result = c1.value * c2.value
		elseif operator == '/' then result = c1.value / c2.value
		elseif operator == '//' then result = math.floor(c1.value / c2.value)
		elseif operator == '%' then result = c1.value % c2.value
		else
			parse_error(token.line, token.col, 'COMPILER BUG: No constant folding rule for operator "'..operator..'"!', file)
		end

		local r = tostring(result)
		if r == tostring(1/0) or r == tostring(0/0) or r == tostring(-(0/0)) then
			parse_error(token.line, token.col, 'Division by zero', file)
		end

		token.value = result
		token.children = nil
		token.text = tostring(result)
		token.id = tok.lit_number

	elseif token.id == tok.comparison then
		local result
		if operator == '==' then result = c1.value == c2.value
		elseif operator == '<' then result = c1.value < c2.value
		elseif operator == '<=' then result = c1.value <= c2.value
		elseif operator == '>' then result = c1.value > c2.value
		elseif operator == '>=' then result = c1.value >= c2.value
		elseif operator == '!=' then result = c1.value ~= c2.value
		else
			parse_error(token.line, token.col, 'COMPILER BUG: No constant folding rule for operator "'..operator..'"!', file)
		end

		token.value = result
		token.children = nil
		token.text = tostring(result)
		token.id = tok.lit_boolean

	elseif token.id == tok.boolean then
		if c2 then --Binary operators
			if operator == 'or' then
				if c1.value and c1.value ~= 0 and c1.value ~= '' then
					token.value, token.id = c1.value, c1.id
				else
					token.value, token.id = c2.value, c2.id
				end
			elseif operator == 'and' then
				if not c1.value or c1.value == 0 or c1.value == '' then
					token.value, token.id = c1.value, c1.id
				else
					token.value, token.id = c2.value, c2.id
				end
			elseif operator == 'xor' then
				local v1 = std.bool(c1.value)
				local v2 = std.bool(c2.value)
				token.value, token.id = (v1 or v2) and not (v1 and v2), tok.lit_boolean
			elseif operator == 'in' then
				local result = false
				if c2.id == tok.lit_array then
					local i
					for i = 1, #c2.value do
						if c2.value[i] == c1.value then
							result = true
							break
						end
					end
				else
					result = std.contains(std.str(c2.value), std.str(c1.value))
				end

				token.value = result
				token.id = tok.lit_boolean
				token.children = nil
				token.text = tostring(result)
			else
				parse_error(token.line, token.col, 'COMPILER BUG: No constant folding rule for operator "'..operator..'"!', file)
			end
			token.children = nil
			token.text = tostring(token.value)
		elseif operator ~= 'exists' then --Unary operators (just "not")
			if c1.value ~= nil or c1.id == tok.lit_null then
				token.value = not c1.value or c1.value == 0 or c1.value == ''
				token.id = tok.lit_boolean
				token.children = nil
				token.text = tostring(token.value)
			elseif c1.id == tok.boolean and c1.text == 'not' then
				--Fold redundant "not" operators
				local ch = c1.children[1]
				token.id, token.text, token.value, token.children = ch.id, ch.text, ch.value, ch.children
			end
		end
	elseif token.id == tok.length then
		if c1.value ~= nil or c1.id == tok.lit_null and (not c1.children or #c1.children == 0) then
			if type(c1.value) ~= 'string' and type(c1.value) ~= 'table' then
				parse_error(token.line, token.col, 'Length operator can only operate on strings and arrays', file)
			end

			token.id = tok.lit_number
			token.value = #c1.value
			token.text = tostring(token.value)
			token.children = nil
		end
	elseif token.id == tok.func_call then
		if func_operations[token.text] then
			--Build list of parameters
			local values = {}
			for i = 1, #token.children do
				table.insert(values, token.children[i].value)
			end

			--Run functions to get resultant value
			local fn = func_operations[token.text]
			local param_ct = builtin_funcs[token.text]
			if param_ct < 0 then
				token.value = fn(values, token, file)
			elseif param_ct == 0 then
				token.value = fn(token, file)
			else
				if #values == 0 then
					token.value = fn(nil, token, file)
				else
					table.insert(values, token)
					table.insert(values, file)
					token.value = fn(table.unpack(values))
				end
			end

			--Fold values of only the deterministic functions
			if token.value ~= nil then
				token.text = tostring(token.value)
				local tp = type(token.value)
				if tp == 'boolean' then token.id = tok.lit_boolean
				elseif tp == 'number' then token.id = tok.lit_number
				elseif tp == 'string' then token.id = tok.string_open
				elseif tp == 'table' then
					token.id = tok.lit_array
					token.text = '[]'
				else
					parse_error(token.line, token.col, 'COMPILER BUG: Folding of function "'..token.text..'" resulted in data of type "'..tp..'"!', file)
				end
				token.children = nil
			end

		elseif math[token.text] then
			local val = math[token.text](c1.value)

			--Check for NaN
			local r = tostring(val)
			if r == tostring(1/0) or r == tostring(0/0) or r == tostring(-(0/0)) then
				parse_error(token.line, token.col, 'Result of "'..token.text..'('..c1.value..')" is not a number', file)
			end

			token.id, token.value, token.text, token.children = tok.lit_number, val, tostring(val), nil
		end
	elseif token.id == tok.array_concat then
		token.id = tok.lit_array
		token.text = '[]'
		token.value = {}
		for i = 1, #token.children do
			--If a slice operator is nested in an array_concat operation, merge the arrays
			if token.children[i].reduce_array_concat then
				local k
				for k = 1, #token.children[i].value do
					table.insert(token.value, token.children[i].value[k])
				end
			else
				table.insert(token.value, token.children[i].value)
			end
		end
		token.children = nil

	elseif token.id == tok.array_slice then
		local start, stop, i = token.children[1].value, token.children[2].value

		--For the sake of performance, don't fold if the array slice is too large!
		if stop - start < 100 then
			token.id = tok.lit_array
			token.text = '[]'
			token.value = {}
			for i = start, stop do
				table.insert(token.value, i)
			end
			token.children = nil
			token.reduce_array_concat = true --If a slice operator is nested in an array_concat operation, merge the arrays
		end

	elseif token.id == tok.negate then
		token.id = tok.lit_number
		token.value = -c1.value
		token.text = tostring(-c1.value)
		token.children = nil

	elseif token.id == tok.concat then
		token.id = tok.string_open
		token.value = std.str(c1.value) .. std.str(c2.value)
		token.text = token.value
		token.children = nil

	elseif token.id == tok.string_open then
		token.value = ''
		local i
		for i = 1, #token.children do
			token.value = token.value .. std.str(token.children[i].value)
		end
		token.children = nil
	else
		parse_error(token.line, token.col, 'COMPILER BUG: No constant folding rule for token id "'..token_text(token.id)..'"!', file)
	end

end