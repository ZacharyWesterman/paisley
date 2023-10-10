local builtin_funcs = {
	irandom = 2,
	frandom = 2,
	worddiff = 2,
	dist2d = 2,
	dist3d = 2,
	sin = 1,
	cos = 1,
	tan = 1,
	asin = 1,
	acos = 1,
	atan = 1,
	atan2 = 1,
	sqrt = 1,
	mean = -1, --mean(a,b,...) = mean(list) = sum(list) / #list
	sum = -1,
	mult = -1,
	pow = 2,
	min = -1,
	max = -1,
	clamp = 3, --clamp(a, b, x) = min(b, max(a, x))
	lerp = 3, --lerp(a, b, x) = a + x*(b - a) : 0 <= x <= 1
	split = 2,
	join = 2,
	type = 1,
	boolean = 1,
	number = 1,
	string = 1,
	array = -2,
	floor = 1,
	ceil = 1,
	round = 1,
}

function SemanticAnalyzer(tokens, file)
	local function recurse(root, token_ids, operation, on_exit)
		local _, id
		local correct_token = false
		for _, id in ipairs(token_ids) do
			if root.id == id then
				correct_token = true
				break
			end
		end

		if correct_token and operation ~= nil then
			operation(root)
		end

		if root.children then
			local _
			local token
			for _, token in ipairs(root.children) do
				recurse(token, token_ids, operation, on_exit)
			end
		end

		if correct_token and on_exit ~= nil then
			on_exit(root)
		end
	end

	local root = tokens[1] --At this point, there should only be one token, the root "program" token.

	--Fold nested array_concat tokens into a single array
	recurse(root, {tok.array_concat}, function(token)
		local child
		local _
		local kids = {}
		for _, child in ipairs(token.children) do
			if child.id == tok.array_concat then
				local __
				local kid
				for __, kid in ipairs(child.children) do
					table.insert(kids, kid)
				end
			else
				table.insert(kids, child)
			end
		end
		token.children = kids
	end)

	--Make a list of all labels
	local labels = {}
	recurse(root, {tok.label}, function(token)
		local label = token.text:sub(1, #token.text - 1)
		local prev = labels[label]
		if prev ~= nil then
			-- Don't allow tokens to be redeclared
			parse_error(token.line, token.col, 'Redeclaration of label "'..label..'" (previously declared on line '..prev.line..', col '..prev.col..')', file)
		end
		labels[label] = token
	end)

	--Check label references
	recurse(root, {tok.goto_stmt, tok.gosub_stmt}, function(token)
		local label = token.children[1].text
		if labels[label] == nil then
			parse_error(token.line, token.col, 'Label "'..label..'" not declared anywhere', file)
		end
	end)


	--Helper func for generating func_call error messages.
	local function funcsig(func_name)
		local param_ct = builtin_funcs[func_name]
		local params = ''
		if param_ct < 0 then
			params = '...'
		elseif param_ct > 0 then
			local i
			for i = 1, param_ct do
				params = params .. string.char(96 + i)
				if i < param_ct then params = params .. ',' end
			end
		end
		return params
	end

	--Check function calls
	recurse(root, {tok.func_call}, function(token)
		local func = builtin_funcs[token.text]

		--Function doesn't exist
		if func == nil then
			local msg = 'Unknown function "'..token.text..'"'
			local guess = closest_word(token.text:lower(), builtin_funcs, 4)

			if guess ~= nil then
				msg = msg .. ' (did you mean "'..guess..'('..funcsig(guess)..')"?)'
			end
			parse_error(token.line, token.col, msg, file)
		end

		if func == -2 then return end --Function can have any number of params

		--Check if function has the right number of params
		local param_ct = 0
		if token.children and #token.children > 0 then
			param_ct = 1
			if token.children[1].id == tok.array_concat then
				param_ct = #(token.children[1].children)
			end
		end

		if func ~= param_ct then
			local plural = ''
			if func ~= 1 then plural = 's' end
			local verb = 'was'
			if param_ct ~= 1 then verb = 'were' end

			if func < 0 then
				if param_ct == 0 then
					parse_error(token.line, token.col, 'Function "'..token.text..'('..funcsig(token.text)..')" expects at least 1 parameter, but '..param_ct..' '..verb..' given', file)
				end
			else
				parse_error(token.line, token.col, 'Function "'..token.text..'('..funcsig(token.text)..')" expects '..func..' parameter'..plural..', but '..param_ct..' '..verb..' given', file)
			end
		end

	end)


	--[[
		CONSTANT FOLDING OPTIMIZATIONS
	]]

	--Get rid of parentheses
	recurse(root, {tok.parentheses}, nil, function(token)
		local key, value
		local child = token.children[1]
		for key, value in pairs(child) do
			token[key] = value
		end
	end)

	--Prep plain (non-interpolated) strings to allow constant folding
	recurse(root, {tok.string_open}, function(token)
		if token.children then
			if token.children[1].id == tok.text and #token.children == 1 then
				token.value = token.children[1].text
				token.children = nil
			end
		else
			token.value = ''
		end
	end)

	--Fold constants. this improves performance at runtime, and checks for type errors early on.
	recurse(root, {tok.add, tok.multiply, tok.boolean, tok.length, tok.func_call, tok.array_concat, tok.negate}, nil, function(token)
		local operator = token.text
		local c1, c2 = token.children[1], token.children[2]

		--Cast boolean token to integer
		local function btoi(t)
			if t.id == tok.lit_boolean then
				t.id = tok.lit_number
				if t.text == 'true' then t.value = 1 else t.value = 0 end
			end
		end


		if token.id == tok.add or token.id == tok.multiply then
			--Cannot perform math on strings. That's an error
			if c1.id == tok.string_open or c2.id == tok.string_open then
				parse_error(token.line, token.col, 'Cannot perform arithmetic on string values', file)
			end

			--Automatically cast booleans to integers
			if c1.id == tok.lit_boolean or c2.id == tok.lit_boolean then
				parse_error(token.line, token.col, 'Cannot perform arithmetic on boolean values', file)
			end

			--Fold the two values into a single value
			if c1.id == tok.lit_number and c2.id == tok.lit_number then
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

				if tostring(result) == tostring(1/0) or tostring(result) == tostring(0/0) then
					parse_error(token.line, token.col, 'Division by zero', file)
				end

				token.value = result
				token.children = nil
				token.text = tostring(result)
				token.id = tok.lit_number
			end
		elseif token.id == tok.boolean and operator ~= 'exists' then
			if c2 then --Binary operators
				if (c1.value ~= nil or c1.id == tok.lit_null) and (c2.value ~= nil or c2.id == tok.lit_null) then
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
						local v1 = c1.value and c1.value ~= 0 and c1.value ~= ''
						local v2 = c2.value and c2.value ~= 0 and c2.value ~= ''
						token.value, token.id = (v1 or v2) and not (v1 and v2), tok.lit_boolean
					else
						parse_error(token.line, token.col, 'COMPILER BUG: No constant folding rule for operator "'..operator..'"!', file)
					end
					token.children = nil
					token.text = tostring(token.value)
				end
			else --Unary operators (just "not")
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
			if c1.value ~= nil or c1.id == tok.lit_null then
				--Fold values of only the deterministic functions
				if token.text == 'string' then
					token.id, token.value, token.text, token.children = tok.string_open, tostring(c1.value), tostring(c1.value), nil
				elseif math[token.text] then
					if type(c1.value) ~= 'number' then
						parse_error(token.line, token.col, 'Function "'..token.text..'('..funcsig(token.text)..')" only accepts a number as input', file)
					end
					local val = math[token.text](c1.value)

					--Check for NaN
					if tostring(val) == tostring(1/0) or tostring(val) == tostring(0/0) then
						parse_error(token.line, token.col, 'Result of "'..token.text..'('..c1.value..')" is not a number', file)
					end

					token.id, token.value, token.text, token.children = tok.lit_number, val, tostring(val), nil
				end
			end
		elseif token.id == tok.array_concat then
			--If an array contains only literals, fold it
			local i
			local all_const = true
			for i = 1, #token.children do
				local ch = token.children[i]
				if not ch.value and ch.id ~= tok.lit_null then
					all_const = false
					break
				end
			end

			if all_const then
				token.id = tok.lit_array
				token.text = '[]'
				token.value = {}
				for i = 1, #token.children do
					table.insert(token.value, token.children[i].value)
				end
				token.children = nil
			end
		elseif token.id == tok.negate then
			if c1.value ~= nil or c1.id == tok.lit_null then
				if type(c1.value) ~= 'number' then
					parse_error(token.line, token.col, 'Cannot get the negative of a non-number', file)
				end

				token.id = tok.lit_number
				token.value = -c1.value
				token.text = tostring(-c1.value)
				token.children = nil
			end
		end

	end)

	return root
end