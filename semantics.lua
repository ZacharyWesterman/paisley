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
	abs = 1,
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
		valid = {{'number'}},
		out = 'number',
	},
	mult = {
		valid = {{'number'}},
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
	[tok.add] = {
		valid = {{'number'}},
		out = 'number',
	},
	[tok.multiply] = {
		valid = {{'number'}},
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
		valid = {{'number'}},
		out = 'number',
	},
	[tok.concat] = {
		out = 'string',
	},
	[tok.length] = {
		out = 'number',
	},
	[tok.string_open] = {
		out = 'string'
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

	--Get rid of parentheses and expression pseudo-tokens
	recurse(root, {tok.parentheses, tok.expression, tok.command}, nil, function(token)
		if not token.children or #token.children ~= 1 then return end

		local key, value
		local child = token.children[1]
		for key, value in pairs(child) do
			token[key] = value
		end
		token.children = child.children
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

	--[[
		TYPE ANNOTATIONS
	]]
	local variables = {}
	local deduced_variable_types

	local function type_checking(token)
		local signature, kind

		if token.value ~= nil or token.id == tok.lit_null then
			token.type = std.type(token.value)
			return
		elseif token.id == tok.variable then
			token.type = variables[token.text]
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
				got_types = std.join(got_types, ',')
				for i = 1, #exp_types do
					exp_types[i] = std.join(exp_types[i], ',')
					if exp_types[i] == got_types then
						found_correct_types = true
						break
					end
				end

				if not found_correct_types then
					local msg
					if builtin_funcs[token.text] then
						msg = 'Function "'..token.text..'('..funcsig(token.text)..')"'
					else
						msg = 'Operator "'..token.text..'"'
					end
					parse_error(token.line, token.col, msg..' expected ('..std.join(exp_types, ' or ')..') but got ('..got_types..')', file)
				end
			end

			token.type = signature.out
		end

	end

	local function variable_assignment(token)
		if token.id == tok.for_stmt then
			local var = token.children[1]
			local ch = token.children[2]

			if var.type then return end

			--Expression to iterate over is constant
			if ch.value ~= nil or ch.id == tok.lit_null then
				if type(ch.value) == 'table' then
					local _, val, tp
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

					--If loop variable has a consistent type, then we know for sure what it will be.
					if tp ~= nil then
						variables[var.text] = tp
						var.type = tp
						deduced_variable_types = true
					end
				else
					local tp = std.type(ch.value)
					variables[var.text] = tp
					var.type = tp
					deduced_variable_types = true
				end
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
		recurse(root, {tok.string_open, tok.add, tok.multiply, tok.boolean, tok.index, tok.array_concat, tok.array_slice, tok.comparison, tok.negate, tok.func_call, tok.concat, tok.length, tok.lit_array, tok.lit_boolean, tok.lit_null, tok.lit_number, tok.variable}, nil, type_checking)

		--Fold constants. this improves performance at runtime, and checks for type errors early on.
		recurse(root, {tok.add, tok.multiply, tok.boolean, tok.length, tok.func_call, tok.array_concat, tok.negate, tok.comparison, tok.concat, tok.array_slice, tok.string_open}, nil, fold_constants)

		--Set any variables we can
		recurse(root, {tok.for_stmt}, variable_assignment)
	end

	return root
end