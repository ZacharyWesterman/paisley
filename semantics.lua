builtin_funcs = {
	irandom = 2,
	frandom = 2,
	worddiff = 2,
	dist = 2,
	sin = 1,
	cos = 1,
	tan = 1,
	asin = 1,
	acos = 1,
	atan = 1,
	atan2 = 2,
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
	bool = 1,
	num = 1,
	str = 1,
	array = -2,
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
	isnumber = 1,
}

type_signatures = {
	irandom = {
		valid = {{'number'}},
		out = 'number',
	},
	frandom = {
		valid = {{'number'}},
		out = 'number',
	},
	worddiff = {
		valid = {{'string'}},
		out = 'number',
	},
	dist = {
		valid = {{'number'}, {'array'}},
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
	mean = {
		valid = {{'number'}},
		out = 'number',
	},
	sum = {
		valid = {{'number', 'array'}},
		out = 'number',
	},
	mult = {
		valid = {{'number', 'array'}},
		out = 'number',
	},
	pow = {
		valid = {{'number'}},
		out = 'number',
	},
	min = {
		valid = {{'number'}},
		out = 'number',
	},
	max = {
		valid = {{'number'}},
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
		out = 'array',
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
	array = {
		out = 'array',
	},
	index = {
		valid = {{'array', 'any'}, {'string', 'any'}},
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
	isnumber = {
		valid = {{'string'}},
		out = 'boolean',
	},
	[tok.add] = {
		valid = {{'number'}, {'array'}},
		out = 'number',
	},
	[tok.multiply] = {
		valid = {{'number'}, {'array'}},
		out = 'number',
	},
	[tok.boolean] = {
		out = 'boolean',
	},
	[tok.array_concat] = {
		out = 'array',
	},
	[tok.array_slice] = {
		out = 'array',
	},
	[tok.comparison] = {
		out = 'boolean',
	},
	[tok.negate] = {
		valid = {{'number'}, {'array'}},
		out = 'number',
	},
	[tok.concat] = {
		out = 'string',
	},
	[tok.length] = {
		out = 'number',
	},
	[tok.string_open] = {
		out = 'string',
	},
}

--Helper func for generating func_call error messages.
function funcsig(func_name)
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

	--Make sure subroutines are top-level statements
	local tok_level = 0
	recurse(root, {tok.subroutine, tok.if_stmt, tok.for_stmt, tok.while_stmt}, function(token)
		--Enter scope
		if token.id == tok.subroutine and tok_level > 0 then
			parse_error(token.line, token.col, 'Subroutines cannot be defined inside other structures', file)
		end
		tok_level = tok_level + 1
	end, function(token)
		--Exit scope
		tok_level = tok_level - 1
	end)

	--Make sure "delete" statements only have text params. deleting expressions that resolve to variable names is a recipe for disaster.
	recurse(root, {tok.delete_stmt}, function(token)
		local kids, i = token.children[1].children
		for i = 1, #kids do
			if kids[i].id ~= tok.text then
				parse_error(kids[i].line, kids[i].col, 'Expected only variable names after "delete" keyword', file)
			end
		end

		token.children = kids
	end)

	--Fold nested array_concat tokens into a single array
	recurse(root, {tok.array_concat}, nil, function(token)
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

	--Make a list of all subroutines, and check that return statements are only in subroutines
	local labels = {}
	local inside_sub = 0
	recurse(root, {tok.subroutine, tok.kwd_return}, function(token)
		if token.id == tok.subroutine then
			inside_sub = inside_sub + 1

			local label = token.text
			local prev = labels[label]
			if prev ~= nil then
				-- Don't allow tokens to be redeclared
				parse_error(token.line, token.col, 'Redeclaration of subroutine "'..label..'" (previously declared on line '..prev.line..', col '..prev.col..')', file)
			end

			if not token.children or #token.children == 0 then
				token.ignore = true
			end

			labels[label] = token
		else
			if inside_sub < 1 then
				parse_error(token.line, token.col, 'Return statements can only be inside subroutines', file)
			end
		end
	end, function(token)
		if token.id == tok.subroutine then
			inside_sub = inside_sub - 1
		end
	end)

	--Check subroutine references
	recurse(root, {tok.gosub_stmt}, function(token)
		local ch = token.children[1]
		if #ch.children > 1 then
			parse_error(token.line, token.col, 'More than one subroutine given to '..token.text, file)
		end

		local label = ch.children[1].text
		if labels[label] == nil then
			local msg = 'Subroutine "'..label..'" not declared anywhere'
			local guess = closest_word(label, labels, 4)
			if guess ~= nil then
				msg = msg .. ' (did you mean "'.. guess ..'"?)'
			end
			parse_error(token.line, token.col, msg, file)
		end

		token.ignore = labels[label].ignore
		token.children = ch.children
	end)

	--Resolve all lambda references
	local lambdas = {}
	local tok_level = 0
	local pop_scope = function(token)
		if token.id == tok.lambda then
			if not lambdas[token.text] then lambdas[token.text] = {} end
			table.insert(lambdas[token.text], {
				level = tok_level,
				node = token.children[1]
			})
		elseif token.id == tok.lambda_ref then
			if not lambdas[token.text] then
				parse_error(token.line, token.col, 'Lambda "'..token.text..'" is not defined in the current scope', file)
			end

			--Lambda is defined, so replace it with the appropriate node
			local lambda_node, i, _ = lambdas[token.text][#lambdas[token.text]].node
			for _, i in ipairs({'text', 'line', 'col', 'id', 'meta_id'}) do
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
	recurse(root, {tok.lambda, tok.lambda_ref, tok.if_stmt, tok.while_stmt, tok.for_stmt, tok.subroutine, tok.else_stmt, tok.elif_stmt}, function(token)
		if token.id ~= tok.lambda and token.id ~= tok.lambda_ref then
			if token.id == tok.else_stmt or token.id == tok.elif_stmt then
				pop_scope(token)
			end
			--Make sure lambdas are only referenced in the appropriate scope, never outside the scope they're defined.
			tok_level = tok_level + 1
		end
	end, pop_scope)

	--Replace lambda definitions with the appropriate node.
	recurse(root, {tok.lambda}, nil, function(token)
		local lambda_node, i, _ = token.children[1]
		for _, i in ipairs({'text', 'line', 'col', 'id', 'meta_id'}) do
			token[i] = lambda_node[i]
		end
		token.children = lambda_node.children
	end)

	--Check function calls
	recurse(root, {tok.func_call}, function(token)
		--Move all params to be direct children
		if not token.children then
			token.children = {}
		elseif #token.children > 0 and token.children[1].id == tok.array_concat then
			token.children = token.children[1].children
		end

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
		local param_ct = #token.children

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

	--Check for variable existence by var name, not value
	recurse(root, {tok.boolean}, function(token)
		local ch = token.children[1]
		if token.text == 'exists' and ch.id == tok.variable then
			ch.id = tok.string_open
			ch.value = ch.text
			ch.type = 'string'
		end
	end)

	--Get rid of parentheses and expression pseudo-tokens
	recurse(root, {tok.parentheses, tok.expression}, nil, function(token)
		if not token.children or #token.children ~= 1 then return end

		local key, value
		local child = token.children[1]
		for key, value in pairs(child) do
			token[key] = value
		end
		token.children = child.children
	end)

	--Prep text to allow constant folding
	recurse(root, {tok.text}, function(token)
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
	recurse(root, {tok.let_stmt}, function(token)
		local body = token.children[2]
		if body and body.id == tok.command then
			if #body.children > 1 then
				body.id = tok.array_concat
				body.text = '[]'
			else
				token.children[2] = body.children[1]
			end
		end
	end)

	--Tidy up WHILE loops and IF/ELIF statements (replace command with cmd contents)
	recurse(root, {tok.while_stmt, tok.if_stmt, tok.elif_stmt}, function(token)
		if #token.children[1].children > 1 then
			parse_error(token.line, token.col, 'Too many parameters passed to "'..token.text..'" statement', file)
		end
		token.children[1] = token.children[1].children[1]
	end)

	--Tidy up FOR loops (replace command with cmd contents)
	recurse(root, {tok.for_stmt}, function(token)
		if token.children[2].id == tok.command then
			if #token.children[2].children > 1 then
				token.children[2].id = tok.array_concat
			else
				for _, i in ipairs({'text', 'line', 'col', 'id', 'meta_id'}) do
					token.children[2][i] = token.children[2].children[1][i]
				end
				token.children[2].children = token.children[2].children[1].children
			end
		end
	end)

	--[[
		TYPE ANNOTATIONS
	]]
	local variables = {}
	local deduced_variable_types

	local function type_checking(token)
		local signature, kind

		--Unlike other tokens, "command" tokens only need the first child to be constant for us to deduce the type
		if token.id == tok.inline_command or token.id == tok.command then
			local ch = token.children[1]
			if token.id == tok.inline_command then ch = ch.children[1] end

			--ignore "define" pseudo-command
			if ch.value == 'define' then return end

			if ch.value ~= nil and ch.id ~= tok.lit_null then
				if not ALLOWED_COMMANDS[ch.value] and not BUILTIN_COMMANDS[ch.value] then
					--If command doesn't exist, try to help user by guessing the closest match (but still throw an error)
					msg = 'Unknown command "'..std.str(ch.value)..'"'
					local guess = closest_word(std.str(ch.value), ALLOWED_COMMANDS, 4)
					if guess == nil or guess == '' then
						guess = closest_word(std.str(ch.value), BUILTIN_COMMANDS, 4)
					end

					if guess ~= nil and guess ~= '' then
						msg = msg .. ' (did you mean "'..std.str(guess)..'"?)'
					end
					parse_error(ch.line, ch.col, msg, file)
				end

				if ALLOWED_COMMANDS[ch.value] then
					token.type = ALLOWED_COMMANDS[ch.value]
				else
					token.type = BUILTIN_COMMANDS[ch.value]
				end
			end
			return
		end

		if token.value ~= nil or token.id == tok.lit_null then
			token.type = std.type(token.value)
			return
		elseif token.id == tok.variable then
			return
		elseif type_signatures[token.id] ~= nil then
			signature = type_signatures[token.id]
		elseif type_signatures[token.text] ~= nil then
			signature = type_signatures[token.text]
		else
			return
		end

		if token.children then
			local i
			local g
			local exp_types, got_types = {}, {}

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

				local found_correct_types = false
				local expt2 = {}
				for i = 1, #exp_types do
					expt2[i] = std.join(exp_types[i], ',')

					local k
					found_correct_types = true
					for k = 1, #exp_types[i] do
						if exp_types[i][k] ~= 'any' and got_types[k] ~= exp_types[i][k] and got_types[k] ~= 'any' then
							found_correct_types = false
							break
						end
					end
					if found_correct_types then break end
				end

				if not found_correct_types then
					local msg
					if builtin_funcs[token.text] then
						msg = 'Function "'..token.text..'('..funcsig(token.text)..')"'
					else
						msg = 'Operator "'..token.text..'"'
					end
					parse_error(token.line, token.col, msg..' expected ('..std.join(expt2, ' or ')..') but got ('..std.join(got_types, ',')..')', file)
				end
			end

			token.type = signature.out
		end

	end

	local function push_var(var, value)
		if not variables[var] then variables[var] = {} end
		table.insert(variables[var], value)
	end

	local function set_var(var, value)
		if not variables[var] then
			variables[var] = {value}
		else
			variables[var][#variables[var]] = value
		end
	end

	local function pop_var(var)
		if variables[var] then
			table.remove(variables[var])
			if #variables[var] == 0 then variables[var] = nil end
		end
	end

	local function variable_assignment(token)
		if token.id == tok.for_stmt then
			local var = token.children[1]
			local ch = token.children[2]

			if var.type then return end

			--Expression to iterate over is constant
			if ch.value ~= nil or ch.id == tok.lit_null then
				local tp

				if type(ch.value) == 'table' then
					local _, val
					for _, val in pairs(ch.value) do
						local _tp = std.type(val)
						if tp == nil then tp = _tp
						elseif tp ~= _tp then
							--Type will change, so it can't be reduced to a constant state.
							--Maybe change this later?
							tp = nil
							break
						end
					end
				else
					tp = std.type(ch.value)
				end

				--If loop variable has a consistent type, then we know for sure what it will be.
				if tp ~= nil then
					push_var(var.text, tp)
					var.type = tp
					deduced_variable_types = true
				end
			end
		end
	end

	local function variable_unassignment(token)
		if token.id == tok.for_stmt then
			local var = token.children[1].text
			if variables[var] then
				if #variables[var] == 1 then
					variables[var] = nil
				else
					table.remove(variables)
				end
			end
		elseif token.id == tok.let_stmt then
			local var = token.children[1]
			local ch = token.children[2]

			if var.type then return end

			if not ch then
				set_var(var.text, 'null')
				var.type = 'null'
				deduced_variable_types = true
			elseif ch.type then
				set_var(var.text, ch.type)
				var.type = ch.type
				deduced_variable_types = true
			end
		elseif token.id == tok.variable then
			if token.type then return end

			local tp = variables[token.text]
			if tp then
				token.type = tp[#tp]
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
		recurse(root, {tok.string_open, tok.add, tok.multiply, tok.boolean, tok.index, tok.array_concat, tok.array_slice, tok.comparison, tok.negate, tok.func_call, tok.concat, tok.length, tok.lit_array, tok.lit_boolean, tok.lit_null, tok.lit_number, tok.inline_command, tok.command}, nil, type_checking)

		--Fold constants. this improves performance at runtime, and checks for type errors early on.
		recurse(root, {tok.add, tok.multiply, tok.boolean, tok.length, tok.func_call, tok.array_concat, tok.negate, tok.comparison, tok.concat, tok.array_slice, tok.string_open, tok.index, tok.ternary}, nil, fold_constants)

		--Set any variables we can
		recurse(root, {tok.for_stmt, tok.let_stmt, tok.variable}, variable_assignment, variable_unassignment)
	end

	--One last pass at deducing all types (after any constant folding)
	recurse(root, {tok.string_open, tok.add, tok.multiply, tok.boolean, tok.index, tok.array_concat, tok.array_slice, tok.comparison, tok.negate, tok.func_call, tok.concat, tok.length, tok.lit_array, tok.lit_boolean, tok.lit_null, tok.lit_number, tok.variable, tok.inline_command, tok.command}, nil, type_checking)


	--BREAK and CONTINUE statements are only allowed to have up to a single CONSTANT INTEGER operand
	recurse(root, {tok.break_stmt, tok.continue_stmt}, function(token)
		if not token.children or #token.children == 0 then
			token.children = {{
				id = tok.lit_number,
				text = '1',
				value = 1,
				line = token.line,
				col = token.col,
			}}
			return
		end

		token.children = token.children[1].children
		local val = token.children[1].value
		if #token.children > 1 or math.type(val) ~= 'integer' or val < 1 then
			parse_error(token.line, token.col, 'Only a constant positive integer is allowed as a parameter for "'..token.text..'"', file)
		end
	end)

	return root
end