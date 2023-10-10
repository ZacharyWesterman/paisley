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
}

function SemanticAnalyzer(tokens, file)
	local function recurse(root, token_ids, operation, on_exit)
		local _
		local id
		for _, id in ipairs(token_ids) do
			if root.id == id then
				operation(root)
				break
			end
		end

		if root.children then
			local _
			local token
			for _, token in ipairs(root.children) do
				recurse(token, token_ids, operation)
			end
		end

		if on_exit ~= nil then
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

	return root
end