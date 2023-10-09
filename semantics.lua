
function SemanticAnalyzer(tokens, file)
	local function recurse(root, token_ids, operation)
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
	end

	local root = tokens[1] --At this point, there should only be one token, the root "program" token.

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
end