func_operations = {
	bytes = function(number, count)
		local result, i = {}
		for i = math.min(4, count), 1, -1 do
			result[i] = math.floor(number) % 256
			number = number / 256
		end
		return result
	end,

	frombytes = function(values)
		local result, i = 0
		for i = 1, #values do
			result = result * 256 + values[i]
		end
		return result
	end,

	sum = function(values)
		local total, i = 0, nil
		for i = 1, #values do
			if type(values[i]) == 'table' then
				local k
				for k = 1, #values[i] do
					total = total + values[i][k]
				end
			else
				total = total + values[i]
			end
		end
		return total
	end,
	mult = function(values)
		local total, i = 1, nil
		for i = 1, #values do
			if type(values[i]) == 'table' then
				local k
				for k = 1, #values[i] do
					total = total * values[i][k]
				end
			else
				total = total * values[i]
			end
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
	clamp = function(value, min, max) return math.min(max, math.max(min, value)) end,
	lerp = function(x, a, b) return a + x * (b - a) end,
	pow = function(a, b) return a ^ b end,
	bool = function(data) return std.bool(data) end,
	str = function(data) return std.str(data) end,
	num = function(data) return std.num(data) end,
	array = function(values) return values end, --Interesting short-cut due to compiler quirks!
	worddiff = function(a, b, token, file) return lev(a, b) end,
	split = function(a, b) return std.split(a, b) end,
	join = function(a, b) return std.join(a, b) end,
	type = function(a) return std.type(a) end,
	dist = function(a, b, token, file)
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
	append = function(a, b)
		table.insert(a, b)
		return a
	end,
	index = function(a, b)
		if type(a) == 'table' then
			return std.arrfind(a, b)
		else
			return std.strfind(a, std.str(b))
		end
	end,
	lower = function(a)
		return std.str(a):lower()
	end,
	upper = function(a)
		return std.str(a):lower()
	end,
	camel = function(a)
		if #a == 0 then return '' end
		return a:sub(1,1):upper() .. a:sub(2,#a):lower()
	end,
	replace = function(subject, search, replace)
		--Not really memory efficient, but good enough.
		return std.join(std.split(subject, search), replace)
	end,

	json_encode = function(data, token, file)
		local result, err = json.stringify(data, nil, true)

		if err ~= nil then
			parse_error(token.line, token.col, err, file)
		end

		return result
	end,
	json_decode = function(data, token, file)
		local result, err = json.parse(data, true)

		if err ~= nil then
			parse_error(token.line, token.col, err, file)
		end

		return result
	end,
	json_valid = function(data)
		return json.verify(data)
	end,

	b64_encode = function(text)
		return std.b64_encode(text)
	end,
	b64_decode = function(text)
		return std.b64_decode(text)
	end,

	lpad = function(text, character, width)
		local c = character:sub(1,1)
		return c:rep(width-#text) .. text
	end,
	rpad = function(text, character, width)
		local c = character:sub(1,1)
		return text .. c:rep(width-#text)
	end,
	hex = function(value)
		return string.format('%x', value)
	end,

	filter = function(text, pattern)
		return std.filter(text, pattern)
	end,
	isnumber = function(text)
		return std.isnumber(text)
	end,
	clocktime = function(value)
		return {
			math.floor(value / 3600),
			math.floor(value / 60) % 60,
			math.floor(value) % 60,
			math.floor(value * 1000) % 1000,
		}
	end,

	reverse = function(value)
		local result, i = {}
		for i = #value, 1, -1 do
			table.insert(result, value[i])
		end
		return result
	end,
	sort = function(value)
		table.sort(value)
		return value
	end,
	merge = function(array1, array2)
		local i
		for i = 1, #array2 do
			table.insert(array1, array2[i])
		end
		return array1
	end,
	update = function(array, index, value)
		array[index] = value
		return array
	end,
	insert = function(array, index, value)
		table.insert(array, index, value)
		return array
	end,
	delete = function(array, index)
		table.remove(array, index)
		return array
	end,
}

local function number_op(v1, v2, operator)
	if type(v1) == 'table' or type(v2) == 'table' then
		if type(v1) ~= 'table' then v1 = {v1} end
		if type(v2) ~= 'table' then v2 = {v2} end

		local result, i = {}
		for i = 1, math.min(#v1, #v2) do
			table.insert(result, operator(std.num(v1[i]), std.num(v2[i])))
		end
		return result
	else
		return operator(std.num(v1), std.num(v2))
	end
end

function fold_constants(token)
	if not token.children then return end

	local operator = token.text
	local c1, c2 = token.children[1], token.children[2]

	local function not_const(token) return token.value == nil and token.id ~= tok.lit_null end

	--Ternary operators are unique: if the condition is constant, they can be folded
	if token.id == tok.ternary then
		local child
		if not_const(c1) then return end
		if std.bool(c1.value) then child = token.children[2] else child = token.children[3] end

		token.id = child.id
		token.value = child.value
		token.text = child.text
		token.line = child.line
		token.col = child.col
		token.children = child.children
		return
	end

	--List comprehension is also unique: if the expression has the form "i for i in EXPR (no condition)" then can optimize the whole list comprehension away.
	if token.id == tok.list_comp and c1.id == tok.variable and c1.text == c2.text and not token.children[4] then
		local child = token.children[3]
		token.id = child.id
		token.value = child.value
		token.text = child.text
		token.line = child.line
		token.col = child.col
		token.children = child.children
		return
	end

	--Another unique case: the reduce() function takes an operator as the second parameter, not a value
	if token.id == tok.func_call and token.text == 'reduce' then
		if c1.value then
			if #c1.value == 0 then
				token.id = tok.lit_null
				token.children = nil
				token.text = tostring(nil)
				return
			end

			operator = c2.text
			local result, i = c1.value[1]
			for i = 2, #c1.value do
				local v = c1.value[i]
				if operator == '==' then result = result == v
				elseif operator == '<' then result = result < v
				elseif operator == '<=' then result = result <= v
				elseif operator == '>' then result = result > v
				elseif operator == '>=' then result = result >= v
				elseif operator == '!=' then result = result ~= v
				elseif operator == '+' then result = std.num(result) + std.num(v)
				elseif operator == '-' then result = std.num(result) - std.num(v)
				elseif operator == '*' then result = std.num(result) * std.num(v)
				elseif operator == '/' then result = std.num(result) / std.num(v)
				elseif operator == '//' then result = math.floor(std.num(result) / std.num(v))
				elseif operator == '%' then result = std.num(result) % std.num(v)
				elseif operator == 'and' then result = std.bool(result) and std.bool(v)
				elseif operator == 'or' then result = std.bool(result) or std.bool(v)
				elseif operator == 'xor' then result = (std.bool(result) or std.bool(v)) and not (std.bool(result) and std.bool(v))
				else
					parse_error(token.line, token.col, 'COMPILER BUG: No constant folding rule for "reduce(a,b)" operator "'..operator..'"!', file)
				end
			end

			token.value = result
			token.text = tostring(result)
			token.children = nil
		else
			--Even if the parameter is not constant, we can still deduce the output type based on the operator
			if std.arrfind({'+', '-', '/', '//', '%'}, c2.text) > 0 then token.type = 'number'
			elseif std.arrfind({'==', '<', '<=', '>', '>=', '!=', 'and', 'or', 'xor'}, c2.text) > 0 then token.type = 'boolean'
			end
		end
		return
	end

	--If this token does not contain only constant children, we cannot fold it.
	local i
	for i = 1, #token.children do
		local ch = token.children[i]
		if ch.value == nil and ch.id ~= tok.lit_null then
			return
		end
	end


	if token.id == tok.add or token.id == tok.multiply then
		--Fold the two values into a single value
		local result
		if operator == '+' then result = number_op(c1.value, c2.value, function(a, b) return a + b end)
		elseif operator == '-' then result = number_op(c1.value, c2.value, function(a, b) return a - b end)
		elseif operator == '*' then result = number_op(c1.value, c2.value, function(a, b) return a * b end)
		elseif operator == '/' then result = number_op(c1.value, c2.value, function(a, b) return a / b end)
		elseif operator == '//' then result = number_op(c1.value, c2.value, function(a, b) return math.floor(c1.value / c2.value) end)
		elseif operator == '%' then result = number_op(c1.value, c2.value, function(a, b) return a % b end)
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
				token.value, token.id = std.bool(c1.value) or std.bool(c2.value), tok.lit_boolean
			elseif operator == 'and' then
				token.value, token.id = std.bool(c1.value) and std.bool(c2.value), tok.lit_boolean
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

			elseif operator == 'like' then
				local v1 = std.str(c1.value)
				local v2 = std.str(c2.value)
				token.value, token.id = v1:match(v2) ~= nil, tok.lit_boolean
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
					local u = table.unpack
					if not u then u = unpack end

					table.insert(values, token)
					table.insert(values, file)
					token.value = fn(u(values))
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

		--For the sake of output bytecode size, don't fold if the array slice is too large!
		if (stop - start) <= 20 then
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
		token.value = number_op(0, c1.value, function(a, b) return a - b end)
		token.text = tostring(token.value)
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

	elseif token.id == tok.index then
		local val = c1.value
		if type(val) == 'string' then
			val = std.split(val, '')
		elseif type(val) ~= 'table' then
			parse_error(token.line, token.col, 'Cannot get subset of a value of type "'..std.type(val)..'"', file)
		end

		local result
		if type(c2.value) == 'table' then
			local i
			result = {}
			for i = 1, #c2.value do
				local ix = c2.value[i]
				if type(ix) ~= 'number' then
					print(std.debug_str(c2.value))
					parse_error(token.line, token.col, 'Cannot use a non-number value as an array index', file)
				end

				if ix < 1 then
					parse_error(token.line, token.col, 'Indexes start at 1, but an index of '..ix..' was found', file)
				end
				table.insert(result, val[ix])
			end
			token.text = '[]'
			token.id = tok.lit_array
		elseif type(c2.value) ~= 'number' then
			parse_error(token.line, token.col, 'Cannot use a non-number value as an array index', file)
		else
			local ix = c2.value
			if type(ix) ~= 'number' then
				parse_error(token.line, token.col, 'Cannot use a non-number value as an array index', file)
			end

			if ix < 1 then
				parse_error(token.line, token.col, 'Indexes start at 1, but an index of '..ix..' was found', file)
			end
			result = val[ix]
			token.text = std.debug_str(result)
			if type(result) == 'string' then token.text = '"' end
		end

		token.value = result
		token.type = std.type(result)
		token.children = nil

		local rs = {
			string = tok.string_open,
			array = tok.text,
			null = tok.lit_null,
			boolean = tok.lit_boolean,
			number = tok.lit_number,
		}
		token.id = rs[token.type]
	else
		parse_error(token.line, token.col, 'COMPILER BUG: No constant folding rule for token id "'..token_text(token.id)..'"!', file)
	end

end
