BUILTIN_FUNCS = {
	random_int = 2,
	random_float = 2,
	word_diff = 2,
	dist = 2,
	sin = 1,
	cos = 1,
	tan = 1,
	asin = 1,
	acos = 1,
	atan = 1,
	atan2 = 2,
	sqrt = 1,
	bytes = 2,
	sum = -1, --at least 1 param
	mult = -1,
	min = -1,
	max = -1,
	clamp = 3, --clamp(a, b, x) = min(b, max(a, x))
	lerp = 3, --lerp(a, b, x) = a + x*(b - a) : 0 <= x <= 1
	split = 2,
	join = 2,
	type = 1,
	bool = 1,
	num = 1,
	str = 1,
	floor = 1,
	ceil = 1,
	round = 1,
	abs = 1,
	append = 2,
	index = 2,
	lower = 1,
	upper = 1,
	camel = 1,
	replace = 3,
	json_encode = 1,
	json_decode = 1,
	json_valid = 1,
	b64_encode = 1,
	b64_decode = 1,
	lpad = 3,
	rpad = 3,
	hex = 1,
	filter = 2,
	match = 2,
	clocktime = 1,
	reverse = 1,
	sort = 1,
	reduce = 2,
	frombytes = 1,
	merge = 2,
	update = 3,
	insert = 3,
	delete = 2,
	random_element = 1,
	hash = 1,
	object = 1,
	array = 1,
	keys = 1,
	values = 1,
	pairs = 1,
	interleave = 2,
	unique = 1,
	union = 2,
	intersection = 2,
	difference = 2,
	symmetric_difference = 2,
	is_disjoint = 2,
	is_subset = 2,
	is_superset = 2,
	count = 2,
	find = 3,
}

local type_signatures = {
	random_int = {
		valid = {{'number'}},
		out = 'number',
	},
	random_float = {
		valid = {{'number'}},
		out = 'number',
	},
	word_diff = {
		valid = {{'string'}},
		out = 'number',
	},
	dist = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
	},
	sin = {
		valid = {{'number'}},
		out = 'number',
	},
	cos = {
		valid = {{'number'}},
		out = 'number',
	},
	tan = {
		valid = {{'number'}},
		out = 'number',
	},
	asin = {
		valid = {{'number'}},
		out = 'number',
	},
	acos = {
		valid = {{'number'}},
		out = 'number',
	},
	atan = {
		valid = {{'number'}},
		out = 'number',
	},
	atan2 = {
		valid = {{'number'}},
		out = 'number',
	},
	sqrt = {
		valid = {{'number'}},
		out = 'number',
	},
	sum = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
	},
	mult = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
	},
	min = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
	},
	max = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
	},
	clamp = {
		valid = {{'number'}},
		out = 'number',
	},
	lerp = {
		valid = {{'number'}},
		out = 'number',
	},
	split = {
		valid = {{'string', 'string'}},
		out = 'array[string]',
	},
	join = {
		valid = {{'array', 'string'}},
		out = 'string',
	},
	floor = {
		valid = {{'number'}},
		out = 'number',
	},
	ceil = {
		valid = {{'number'}},
		out = 'number',
	},
	round = {
		valid = {{'number'}},
		out = 'number',
	},
	abs = {
		valid = {{'number'}},
		out = 'number',
	},
	append = {
		valid = {{'array', 'any'}},
		out = 'array',
	},
	type = {
		out = 'string',
	},
	bool = {
		out = 'boolean',
	},
	num = {
		out = 'number',
	},
	str = {
		out = 'string',
	},
	index = {
		valid = {{'array', 'array[number]'}, {'array', 'number'}, {'string', 'array[number]'}, {'string', 'number'}},
		out = 'number',
	},
	lower = {
		valid = {{'string'}},
		out = 'string',
	},
	upper = {
		valid = {{'string'}},
		out = 'string',
	},
	camel = {
		valid = {{'string'}},
		out = 'string',
	},
	replace = {
		valid = {{'string'}},
		out = 'string',
	},
	json_encode = {
		out = 'string',
	},
	json_decode = {
		valid = {{'string'}},
	},
	json_valid = {
		out = 'boolean',
	},
	b64_encode = {
		valid = {{'string'}},
		out = 'string',
	},
	b64_decode = {
		valid = {{'string'}},
		out = 'string',
	},
	lpad = {
		valid = {{'string', 'string', 'number'}},
		out = 'string',
	},
	rpad = {
		valid = {{'string', 'string', 'number'}},
		out = 'string',
	},
	hex = {
		valid = {{'number'}},
		out = 'string',
	},
	filter = {
		valid = {{'string', 'string'}},
		out = 'string',
	},
	match = {
		valid = {{'string', 'string'}},
		out = 'string',
	},
	clocktime = {
		valid = {{'number'}},
		out = 'array[number]',
	},
	reverse = {
		valid = {{'array'}, {'string'}},
		out = 1, --output type is the same as that of the first parameter
	},
	sort = {
		valid = {{'array'}},
		out = 'array',
	},
	reduce = {
		valid = {{'array', 'any'}},
	},
	bytes = {
		valid = {{'number'}},
		out = 'array[number]',
	},
	frombytes = {
		valid = {{'array[number]'}},
		out = 'number',
	},
	merge = {
		valid = {{'array'}},
		out = 'array',
	},
	update = {
		valid = {{'array', 'number', 'any'}},
		out = 'array',
	},
	insert = {
		valid = {{'array', 'number', 'any'}},
		out = 'array',
	},
	delete = {
		valid = {{'array', 'number'}},
		out = 'array',
	},
	random_element = {
		valid = {{'array'}},
		out = 'any',
	},
	hash = {
		valid = {{'string'}},
		out = 'string',
	},
	object = {
		valid = {{'array'}},
		out = 'object',
	},
	array = {
		valid = {{'object'}},
		out = 'array',
	},
	keys = {
		valid = {{'object'}},
		out = 'array[string]',
	},
	values = {
		valid = {{'object'}},
		out = 'array',
	},
	pairs = {
		valid = {{'object'}, {'array'}},
		out = 'array',
	},
	interleave = {
		valid = {{'array'}},
		out = 'array',
	},
	unique = {
		valid = {{'array'}},
		out = 'array',
	},
	union = {
		valid = {{'array'}},
		out = 'array',
	},
	intersection = {
		valid = {{'array'}},
		out = 'array',
	},
	difference = {
		valid = {{'array'}},
		out = 'array',
	},
	symmetric_difference = {
		valid = {{'array'}},
		out = 'array',
	},
	is_disjoint = {
		valid = {{'array'}},
		out = 'boolean',
	},
	is_subset = {
		valid = {{'array'}},
		out = 'boolean',
	},
	is_superset = {
		valid = {{'array'}},
		out = 'boolean',
	},
	count = {
		valid = {{'array','any'}, {'string'}},
		out = 'number',
	},
	find = {
		valid = {{'array','any','number'},{'string','string','number'}},
		out = 'number',
	},

	[TOK.add] = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
	},
	[TOK.multiply] = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
	},
	[TOK.exponent] = {
		valid = {{'number'}},
		out = 'number',
	},
	[TOK.boolean] = {
		out = 'boolean',
	},
	[TOK.array_concat] = {
		out = 'array',
	},
	[TOK.array_slice] = {
		valid = {{'number', 'number'}},
		out = 'array[number]',
	},
	[TOK.comparison] = {
		out = 'boolean',
	},
	[TOK.negate] = {
		valid = {{'number'}, {'array'}},
		out = 'number',
	},
	[TOK.concat] = {
		out = 'string',
	},
	[TOK.length] = {
		out = 'number',
	},
	[TOK.string_open] = {
		out = 'string',
	},
	[TOK.list_comp] = {
		out = 'array',
	},
}

--Helper func for generating func_call error messages.
local function funcsig(func_name)
	local param_ct = BUILTIN_FUNCS[func_name]
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

function SemanticAnalyzer(tokens, file)
	--[[minify-delete]] SHOW_MULTIPLE_ERRORS = true --[[/minify-delete]]

	---@param root Token
	---@param token_ids TOK[]
	---@param operation fun(token: Token, file: string?)?
	---@param on_exit fun(token: Token, file: string?)?
	local function recurse(root, token_ids, operation, on_exit)
		local correct_token = false
		for _, id in ipairs(token_ids) do
			if root.id == id then
				correct_token = true
				break
			end
		end

		if correct_token and operation ~= nil then
			operation(root, file)
		end

		if root.children then
			for _, token in ipairs(root.children) do
				recurse(token, token_ids, operation, on_exit)
			end
		end

		if correct_token and on_exit ~= nil then
			on_exit(root, file)
		end
	end

	local root = tokens[1] --At this point, there should only be one token, the root "program" token.

	--Make sure subroutines are top-level statements
	local tok_level = 0
	recurse(root, {TOK.subroutine, TOK.if_stmt, TOK.for_stmt, TOK.while_stmt}, function(token)
		--Enter scope
		if token.id == TOK.subroutine and tok_level > 0 then
			parse_error(token.span, 'Subroutines cannot be defined inside other structures', file)
		end

		if token.text:sub(1,1) == '?' then
			parse_error(token.span, 'Subroutine name cannot begin with `?`', file)
		end

		tok_level = tok_level + 1
	end, function(token)
		--Exit scope
		tok_level = tok_level - 1
	end)

	--Make sure "delete" statements only have text params. deleting expressions that resolve to variable names is a recipe for disaster.
	recurse(root, {TOK.delete_stmt}, function(token)
		---@type Token[]
		local kids = token.children[1].children
		for i = 1, #kids do
			if kids[i].id ~= TOK.text then
				parse_error(kids[i].span, 'Expected only variable names after "delete" keyword', file)
			end
		end

		token.children = kids
	end)

	--Fold nested array_concat tokens into a single array
	recurse(root, {TOK.array_concat}, nil, function(token)
		local kids = {}
		for _, child in ipairs(token.children) do
			if child.id == TOK.array_concat or child.id == TOK.object then
				for __, kid in ipairs(child.children) do
					table.insert(kids, kid)
				end
			else
				table.insert(kids, child)
			end
		end

		local is_object = false
		local is_array = false
		for _, child in ipairs(kids) do
			if child.id ~= TOK.array_concat and child.id ~= TOK.object and not child.errored then
				if child.id == TOK.key_value_pair then
					is_object = true
					child.inside_object = true
					if #child.children == 0 and #kids > 1 then
						parse_error(child.span, 'Missing key and value for object construct')
						child.errored = true
					end
				else is_array = true end

				if is_object and is_array then
					parse_error(child.span, 'Ambiguous mixture of object and array constructs. Objects require key-value pairs for every element (e.g. `"key" => value`)')
					child.errored = true
					break
				end
			end
		end

		if is_object then
			token.id = TOK.object
			token.type = 'object'
		end
		token.children = kids
	end)

	--Extract key-value pairs into objects
	recurse(root, {TOK.key_value_pair}, nil, function(token)
		if not token.inside_object then
			local new_token = {
				id = token.id,
				span = token.span,
				text = token.text,
				children = token.children,
			}
			token.id = TOK.object
			token.text = '{}'
			token.type = 'object'
			token.children = {new_token}
		end
	end)

	--Make a list of all subroutines, and check that return statements are only in subroutines
	local labels = {}
	local inside_sub = 0
	recurse(root, {TOK.subroutine, TOK.kwd_return}, function(token)
		if token.id == TOK.subroutine then
			inside_sub = inside_sub + 1

			local label = token.text
			local prev = labels[label]
			if prev ~= nil then
				-- Don't allow tokens to be redeclared
				parse_error(token.span, 'Redeclaration of subroutine "'..label..'" (previously declared on line '..prev.span.from.line..', col '..prev.span.from.col..')', file)
			end

			if not token.children or #token.children == 0 then
				token.ignore = true
			end

			labels[label] = token
		else
			if inside_sub < 1 then
				parse_error(token.span, 'Return statements can only be inside subroutines', file)
			end
		end
	end, function(token)
		if token.id == TOK.subroutine then
			inside_sub = inside_sub - 1
		end
	end)

	--Check subroutine references.
	recurse(root, {TOK.gosub_stmt}, function(token)
		token.children = token.children[1].children
	end)

	--Resolve all lambda references
	local lambdas = {}
	local tok_level = 0
	local pop_scope = function(token)
		if token.id == TOK.lambda then
			if not lambdas[token.text] then lambdas[token.text] = {} end
			table.insert(lambdas[token.text], {
				level = tok_level,
				node = token.children[1]
			})
		elseif token.id == TOK.lambda_ref then
			if not lambdas[token.text] then
				parse_error(token.span, 'Lambda "'..token.text..'" is not defined in the current scope', file)
			end

			--Lambda is defined, so replace it with the appropriate node
			local lambda_node = lambdas[token.text][#lambdas[token.text]].node
			for _, i in ipairs({'text', 'span', 'id', 'value', 'type'}) do
				token[i] = lambda_node[i]
			end
			token.children = lambda_node.children
		else
			tok_level = tok_level - 1
			--Make sure lambdas are only referenced in the appropriate scope, never outside the scope they're defined.
			local i
			for i in pairs(lambdas) do
				while lambdas[i][#lambdas[i]].level > tok_level do
					table.remove(lambdas[i])
					if #lambdas[i] == 0 then
						lambdas[i] = nil
						break
					end
				end
			end
		end
	end
	recurse(root, {TOK.lambda, TOK.lambda_ref, TOK.if_stmt, TOK.while_stmt, TOK.for_stmt, TOK.subroutine, TOK.else_stmt, TOK.elif_stmt}, function(token)
		if token.id ~= TOK.lambda and token.id ~= TOK.lambda_ref then
			if token.id == TOK.else_stmt or token.id == TOK.elif_stmt then
				pop_scope(token)
			end
			--Make sure lambdas are only referenced in the appropriate scope, never outside the scope they're defined.
			tok_level = tok_level + 1
		end
	end, pop_scope)

	--Replace lambda definitions with the appropriate node.
	recurse(root, {TOK.lambda}, nil, function(token)
		local lambda_node = token.children[1]
		for _, i in ipairs({'text', 'span', 'id', 'value', 'type'}) do
			token[i] = lambda_node[i]
		end
		token.children = lambda_node.children
	end)

	--Check function calls
	recurse(root, {TOK.func_call}, function(token)
		--Move all params to be direct children
		if not token.children then
			token.children = {}
		elseif #token.children > 0 then
			local kids = {}
			for i = 1, #token.children do
				local child = token.children[i]
				if token.children[i].id == TOK.array_concat then
					local k
					for k = 1, #token.children[i].children do
						table.insert(kids, token.children[i].children[k])
					end
				else
					table.insert(kids, token.children[i])
				end
			end

			token.children = kids
		end

		local func = BUILTIN_FUNCS[token.text]

		--Function doesn't exist
		if func == nil then
			local msg = 'Unknown function "'..token.text..'"'
			local guess = closest_word(token.text:lower(), BUILTIN_FUNCS, 4)

			if guess ~= nil then
				msg = msg .. ' (did you mean "'..guess..'('..funcsig(guess)..')"?)'
			end
			parse_error(token.span, msg, file)
			return
		end

		--Check if function has the right number of params
		local param_ct = #token.children

		if func ~= param_ct then
			local plural = ''
			if func ~= 1 then plural = 's' end
			local verb = 'was'
			if param_ct ~= 1 then verb = 'were' end

			if func < 0 then
				if param_ct < -func then
					local plural = ''
					if func < -1 then plural = 's' end
					parse_error(token.span, 'Function "'..token.text..'('..funcsig(token.text)..')" expects at least '..(-func)..' parameter'..plural..', but '..param_ct..' '..verb..' given', file)
				end
			else
				parse_error(token.span, 'Function "'..token.text..'('..funcsig(token.text)..')" expects '..func..' parameter'..plural..', but '..param_ct..' '..verb..' given', file)
			end
		end

		--For reduce() function, make sure that its second parameter is an operator!
		if token.text == 'reduce' then
			local correct = false
			for i, k in pairs({TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_idiv, TOK.op_div, TOK.op_mod, TOK.op_and, TOK.op_or, TOK.op_xor, TOK.op_ge, TOK.op_gt, TOK.op_le, TOK.op_lt, TOK.op_eq, TOK.op_ne}) do
				if token.children[2].id == k then
					correct = true
					break
				end
			end
			if not correct then
				parse_error(token.children[2].span, 'The second parameter of "reduce(a,b)" must be a binary operator', file)
			end
		elseif token.text == 'clamp' then
			--Convert "clamp" into max(min(upper_bound, x), lower_bound)
			---@type Token
			local mintok = {
				id = token.id,
				span = token.span,
				text = 'min',
				children = {
					token.children[1],
					token.children[3],
				},
			}
			token.text = 'max'
			token.children = {mintok, token.children[2]}
		end
	end)

	--Prep plain (non-interpolated) strings to allow constant folding
	recurse(root, {TOK.string_open}, function(token)
		if token.children then
			if token.children[1].id == TOK.text and #token.children == 1 then
				token.value = token.children[1].text
				token.children = nil
			end
		else
			token.value = ''
		end
	end)

	--Check for variable existence by var name, not value
	recurse(root, {TOK.boolean}, function(token)
		local ch = token.children[1]
		if token.text == 'exists' and ch.id == TOK.variable then
			ch.id = TOK.string_open
			ch.value = ch.text
			ch.type = 'string'
		end
	end)

	--Get rid of parentheses and expression pseudo-tokens
	recurse(root, {TOK.parentheses, TOK.expression}, nil, function(token)
		if not token.children or #token.children ~= 1 then return end

		local child = token.children[1]
		for _, key in ipairs({'value', 'id', 'text', 'span', 'type'}) do
			token[key] = child[key]
		end
		token.children = child.children
	end)

	--Prep text to allow constant folding
	recurse(root, {TOK.text}, function(token)
		local val = tonumber(token.text)
		if val then
			token.value = val
			token.type = 'number'
		else
			token.value = token.text
			token.type = 'string'
		end
	end)

	--Make variable assignment make sense, removing quirks of AST generation.
	recurse(root, {TOK.let_stmt}, function(token, file)
		local body = token.children[2]
		if body and body.id == TOK.command then
			if #body.children > 1 then
				body.id = TOK.array_concat
				body.text = '[]'
			else
				token.children[2] = body.children[1]
			end
		end

		--Make sure there are no redundant variable assignments
		if token.children[1].children then
			local vars = {[token.children[1].text] = true}
			for i = 1, #token.children[1].children do
				local child = token.children[1].children[i]
				if child.text ~= '_' and vars[child.text] then
					parse_error(child.span, 'Redundant variable `'..child.text..'` in group assignment. To indicate that this element should be ignored, use an underscore for the variable name.', file)
				end
				vars[child.text] = true
			end
		end
	end)

	--Tidy up WHILE loops and IF/ELIF statements (replace command with cmd contents)
	recurse(root, {TOK.while_stmt, TOK.if_stmt, TOK.elif_stmt}, function(token)
		if token.children[1].id ~= TOK.gosub_stmt then
			if #token.children[1].children > 1 then
				parse_error(token.span, 'Too many parameters passed to "'..token.text..'" statement', file)
			end
			token.children[1] = token.children[1].children[1]
		end
	end)

	--Tidy up FOR loops (replace command with cmd contents)
	recurse(root, {TOK.for_stmt}, function(token)
		if token.children[2].id == TOK.command then
			if #token.children[2].children > 1 then
				token.children[2].id = TOK.array_concat
			else
				for _, i in ipairs({'text', 'span', 'id', 'value', 'type'}) do
					token.children[2][i] = token.children[2].children[1][i]
				end
				token.children[2].children = token.children[2].children[1].children
			end
		end

		--Don't automatically set var type to "string", let it deduce.
		if token.children[1].id == TOK.text then
			token.children[1].id = TOK.var_assign
			token.children[1].value = nil
			token.children[1].type = nil
		end
	end)

	--[[
		TYPE ANNOTATIONS
	]]
	local variables = {}
	local deduced_variable_types

	local function type_checking(token, file)
		local signature

		--Unlike other tokens, "command" tokens only need the first child to be constant for us to deduce the type
		if token.id == TOK.inline_command or token.id == TOK.command then
			local ch = token.children[1]
			if ch.id == TOK.gosub_stmt then return end --subroutine eval is different

			if token.id == TOK.inline_command then ch = ch.children[1] end

			--ignore "define" pseudo-command
			if ch.value == 'define' then return end

			if ch.value ~= nil and ch.id ~= TOK.lit_null then
				if not ALLOWED_COMMANDS[ch.value] and not BUILTIN_COMMANDS[ch.value] then
					--If command doesn't exist, try to help user by guessing the closest match (but still throw an error)
					local msg = 'Unknown command "'..std.str(ch.value)..'"'
					local guess = closest_word(std.str(ch.value), ALLOWED_COMMANDS, 4)
					if guess == nil or guess == '' then
						guess = closest_word(std.str(ch.value), BUILTIN_COMMANDS, 4)
					end

					if guess ~= nil and guess ~= '' then
						msg = msg .. ' (did you mean "'..std.str(guess)..'"?)'
					end
					parse_error(token.span, msg, file)
				end

				if ALLOWED_COMMANDS[ch.value] then
					token.type = ALLOWED_COMMANDS[ch.value]
				else
					token.type = BUILTIN_COMMANDS[ch.value]
				end
			end
			return
		end

		if token.value ~= nil or token.id == TOK.lit_null then
			token.type = std.deep_type(token.value)
			return
		elseif token.id == TOK.index then
			local c2 = token.children[2]
			if c2.id == TOK.array_slice and #c2.children == 1 then
				c2.unterminated = true
			end

			local t1, t2 = token.children[1].type, token.children[2].type
			if t1 and t2 then
				if t1 ~= 'string' and t1:sub(1,5) ~= 'array' and t1 ~= 'object' then
					parse_error(token.children[1].span, 'Cannot index a value of type `'..t1..'`. Type must be `string`,  `array`, or `object`', file)
					return
				end

				if t1 == 'string' then
					token.type = t1
				elseif t2 == 'array' then
					token.type = t2
				else
					if t1:sub(6,6) == '[' then
						token.type = t1:sub(7, #t1 - 1)
					else
						--We don't know what type of array this is, so result of non-const array index has to be "any"
						token.type = 'any'
					end
				end
			end
			return
		elseif token.id == TOK.variable then
			return
		elseif type_signatures[token.id] ~= nil then
			signature = type_signatures[token.id]
		elseif type_signatures[token.text] ~= nil then
			signature = type_signatures[token.text]
		else
			return
		end

		if token.children then
			local exp_types, got_types = {}, {}
			local found_correct_types = false

			if signature.valid then
				for g = 1, #signature.valid do
					table.insert(exp_types, {})
				end

				for i = 1, #token.children do
					local tp = token.children[i].type
					if tp then
						for g = 1, #signature.valid do
							local s = signature.valid[g]
							table.insert(exp_types[g], s[(i-1) % #s + 1])
						end
						table.insert(got_types, tp)
					end
				end

				local expt2 = {}
				for i = 1, #exp_types do
					expt2[i] = std.join(exp_types[i], ',')

					found_correct_types = true
					for k = 1, #exp_types[i] do
						local t1, t2 = exp_types[i][k], got_types[k]
						if t1 ~= 'any' and t2 ~= 'any' and t1 ~= t2 then
							if t1 ~= 'array' or t2:sub(1,5) ~= 'array' then
								found_correct_types = false
								break
							end
						end
					end
					if found_correct_types then break end
				end

				if not found_correct_types then
					local msg
					if BUILTIN_FUNCS[token.text] then
						msg = 'Function "'..token.text..'('..funcsig(token.text)..')"'
					else
						msg = 'Operator "'..token.text..'"'
					end
					parse_error(token.span, msg..' expected ('..std.join(expt2, ' or ')..') but got ('..std.join(got_types, ',')..')', file)
				end
			end

			if signature.out then
				if type(signature.out) == 'number' then
					if found_correct_types then token.type = got_types[signature.out] end
				elseif signature.out == 'array' and #token.children > 0 then
					local subtype = token.children[1].type
					for i = 2, #token.children do
						if token.children[i].type ~= subtype then
							subtype = nil
							break
						end
					end
					if subtype then token.type = 'array[' .. subtype .. ']' else token.type = 'array' end
				else
					token.type = signature.out
				end
			end
		end

	end

	local function push_var(var, value)
		if not variables[var] then variables[var] = {} end
		table.insert(variables[var], {
			text = value,
			line = var.span.from.line,
			col = var.span.from.col,
		})
	end

	local function set_var(var, value)
		if not variables[var.text] then variables[var.text] = {} end
		variables[var.text][#variables[var.text]] = {
			text = value,
			line = var.span.from.line,
			col = var.span.from.col,
		}
	end

	local function pop_var(var)
		if variables[var] then
			table.remove(variables[var])
			if #variables[var] == 0 then variables[var] = nil end
		end
	end

	local function variable_assignment(token)
		if token.id == TOK.for_stmt then
			local var = token.children[1]
			local ch = token.children[2]

			if var.type then return end

			--Expression to iterate over is constant
			if ch.value ~= nil or ch.id == TOK.lit_null then
				local tp

				if type(ch.value) == 'table' then
					for _, val in pairs(ch.value) do
						local _tp = std.deep_type(val)
						if tp == nil then tp = _tp
						elseif tp ~= _tp then
							--Type will change, so it can't be reduced to a constant state.
							--Maybe change this later?
							tp = nil
							break
						end
					end
				else
					tp = std.deep_type(ch.value)
				end

				--If loop variable has a consistent type, then we know for sure what it will be.
				if tp ~= nil then
					push_var(var, tp)
					var.type = tp
					deduced_variable_types = true
				end
			end
		end
	end

	local function variable_unassignment(token)
		if token.id == TOK.for_stmt then
			local var = token.children[1].text
			local ch = token.children[2]
			if variables[var] then
				if #variables[var] == 1 then
					variables[var] = nil
				else
					table.remove(variables)
				end
			end

			if ch.type and ch.type:sub(1,5) == 'array' and ch.type:sub(6,6) == '[' then
				token.children[1].type = ch.type:sub(7, #ch.type - 1)
			end
		elseif token.id == TOK.let_stmt then
			local var = token.children[1]
			local ch = token.children[2]

			if var.type then return end

			if #token.children > 2 then
				--Don't deduce types for let statements that are updating variables.
				--Those don't define what the variable's actual type is.
				return
			end

			local tp = nil
			if ch and ch.type then tp = ch.type end

			if var.children then
				local vars = {var.text}
				for i = 1, #var.children do
					table.insert(vars, var.children[i].text)
				end

				for i = 1, #vars do
					tp = nil
					if ch then
						if ch.id == TOK.array_concat then
							if ch.children[i] and ch.children[i].type then
								tp = ch.children[i].type
							end
						elseif ch.value or ch.id == TOK.lit_null then
							if ch.id == TOK.lit_array then
								tp = std.deep_type(ch.value[i])
							elseif i == 1 then
								tp = std.deep_type(ch.value)
							else
								tp = 'null'
							end
						else
							tp = 'any'
						end
					else
						tp = 'null'
					end

					if tp ~= nil then
						local child = var
						if i > 1 then child = var.children[i-1] end
						set_var(child, tp)
						child.type = tp
						deduced_variable_types = true
					end
				end
			elseif tp ~= nil then
				set_var(var, tp)
				var.type = tp
				deduced_variable_types = true
			end

		elseif token.id == TOK.variable then
			if token.type then return end

			local tp = variables[token.text]
			if tp then
				local tp1 = tp[#tp]
				if tp1.line > token.span.from.line or (tp1.line == token.span.from.line and tp1.col > token.span.from.col) then
					if #tp < 2 then return end
					token.type = tp[#tp - 1].text
				else
					token.type = tp[#tp].text
				end
			elseif token.text == '@' then
				token.type = 'array[string]'
			elseif token.text == '$' then
				token.type = 'array'
			end
		end
	end

	--[[
		CONSTANT FOLDING AND TYPE DEDUCTIONS
	]]
	deduced_variable_types = true
	while deduced_variable_types do
		deduced_variable_types = false

		--First pass at deducing all types
		recurse(root, {TOK.string_open, TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.index, TOK.array_concat, TOK.array_slice, TOK.comparison, TOK.negate, TOK.func_call, TOK.concat, TOK.length, TOK.lit_array, TOK.lit_boolean, TOK.lit_null, TOK.lit_number, TOK.inline_command, TOK.command}, nil, type_checking)

		--Fold constants. this improves performance at runtime, and checks for type errors early on.
		recurse(root, {TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.length, TOK.func_call, TOK.array_concat, TOK.negate, TOK.comparison, TOK.concat, TOK.array_slice, TOK.string_open, TOK.index, TOK.ternary, TOK.list_comp, TOK.object, TOK.key_value_pair}, nil, FOLD_CONSTANTS)

		--Set any variables we can
		recurse(root, {TOK.for_stmt, TOK.let_stmt, TOK.variable}, variable_assignment, variable_unassignment)

		if ERRORED then break end
	end

	--If running as language server, print type info for any variable declarations or command calls.
	--[[minify-delete]]
	if _G['LANGUAGE_SERVER'] then
		recurse(root, {TOK.let_stmt, TOK.for_stmt, TOK.inline_command}, function(token)
			local var = token.children[1]
			if token.id == TOK.inline_command then
				local cmd = var.children[1]
				if cmd.value then
					local tp
					if ALLOWED_COMMANDS[cmd.value] then
						tp = ALLOWED_COMMANDS[cmd.value]
					else
						tp = BUILTIN_COMMANDS[cmd.value]
					end

					INFO.hint(cmd.span, 'returns: '..tp)
				end
			else
				if var.type then
					INFO.hint(var.span, 'type: '..var.type)
				end
			end
		end)
	end
	--[[/minify-delete]]

	if ERRORED then terminate() end

	--One last pass at deducing all types (after any constant folding)
	recurse(root, {TOK.string_open, TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.index, TOK.array_concat, TOK.array_slice, TOK.comparison, TOK.negate, TOK.func_call, TOK.concat, TOK.length, TOK.lit_array, TOK.lit_boolean, TOK.lit_null, TOK.lit_number, TOK.variable, TOK.inline_command, TOK.command}, nil, type_checking)


	--BREAK and CONTINUE statements are only allowed to have up to a single CONSTANT INTEGER operand
	recurse(root, {TOK.break_stmt, TOK.continue_stmt}, function(token)
		if not token.children or #token.children == 0 then
			token.children = {{
				id = TOK.lit_number,
				text = '1',
				value = 1,
				span = token.span,
			}}
			return
		end

		token.children = token.children[1].children
		local val = token.children[1].value
		if #token.children > 1 or math.type(val) ~= 'integer' or val < 1 then
			parse_error(token.span, 'Only a constant positive integer is allowed as a parameter for "'..token.text..'"', file)
		end
	end)

	--Check gosub uses. Gosub IS allowed to have a single, constant value as its parameter.
	recurse(root, {TOK.gosub_stmt}, function(token)
		local label
		if token.children[1].value ~= nil or token.children[1].id == TOK.lit_null then
			label = std.str(token.children[1].value)
		elseif token.children[1].id == TOK.text then
			label = token.children[1].text
		end

		if label == nil then
			local l = {}
			for k, i in pairs(labels) do table.insert(l, k) end
			token.all_labels = l
			return
		end

		if labels[label] == nil then
			local msg = 'Subroutine "'..label..'" not declared anywhere'
			local guess = closest_word(label, labels, 4)
			if guess ~= nil and guess ~= '' then
				msg = msg .. ' (did you mean "'.. guess ..'"?)'
			end
			parse_error(token.children[1].span, msg, file)
		end

		token.ignore = labels[label].ignore
	end)

	if ERRORED then terminate() end

	return root
end
