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
	recurse(root, {tok.add, tok.multiply, tok.boolean, tok.length, tok.func_call, tok.array_concat, tok.negate}, nil, fold_constants)

	return root
end