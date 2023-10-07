local rules = {
	--Treat all literals the same.
	{
		match = {{tok.lit_number, tok.lit_false, tok.lit_true, tok.lit_null, tok.negate}},
		id = tok.value,
		meta = true,
	},

	--Unary negation is a bit weird; highest precedence and cannot occur after certain nodes.
	{
		match = {{tok.op_minus}, {tok.value}},
		id = tok.negate,
		keep = {2},
		text = 1,
		not_after = {tok.lit_number, tok.lit_false, tok.lit_true, tok.lit_null, tok.negate},
	},

	--Multiplication
	{
		match = {{tok.value, tok.multiply}, {tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod}, {tok.value}},
		id = tok.multiply,
		keep = {1, 3},
		text = 2,
	},

	--If no other multiplication was detected, just promote the value to mult status.
	--This is to keep mult as higher precedence than addition.
	{
		match = {{tok.value}},
		id = tok.multiply,
		meta = true,
	},

	--Addition (lower precedence than multiplication)
	{
		match = {{tok.multiply, tok.add}, {tok.op_plus, tok.op_minus}, {tok.multiply}},
		id = tok.add,
		keep = {1, 3},
		text = 2,
	},

	{
		match = {{tok.expr_open}, {tok.add}, {tok.expr_close}},
		id = tok.expression,
		keep = {2},
		text = 1,
	},

}

function syntax(tokens, file)

	local function matches(index, rule, rule_index)
		local this_token = tokens[index]
		local group = rule.match[rule_index]

		local _
		local _t
		for _, _t in ipairs(group) do
			if (this_token.meta_id == nil and this_token.id == _t) or this_token.meta_id == _t then
				return true
			end
		end

		return false
	end

	--Returns nil, nil, unexpected token index if reduce failed. If successful, returns a token, and the number of tokens consumed
	local function reduce(index)
		local _, rule
		local this_token = tokens[index]
		local greatest_len = 0
		local unexpected_token = 1

		for _, rule in ipairs(rules) do
			local rule_index
			local rule_matches = true

			if #rule.match + index - 1 <= #tokens then
				local rule_failed = false
				if rule.not_after and index > 1 then
					local i
					local prev_token = tokens[index - 1]
					for i = 1, #rule.not_after do
						if prev_token.id == rule.not_after[i] then
							rule_failed = true
							break
						end
					end
				end

				if rule_failed then
					rule_matches = false
				else
					for rule_index = 1, #rule.match do
						if not matches(index + rule_index - 1,  rule, rule_index) then
							rule_matches = false
							if rule_index > greatest_len then
								greatest_len = rule_index
								unexpected_token = index + rule_index - 1
								break
							end
						end
					end
				end

				if rule_matches then
					if rule.meta and #rule.match == 1 then
						--This is a "meta" rule. It reduces a token by just changing the id.
						this_token.meta_id = rule.id
						return this_token, 1, nil
					else
						local text = '<undefined>'
						if rule.text ~= nil then
							text = tokens[index + rule.text - 1].text
						end

						local new_token = {
							text = text,
							id = rule.id,
							line = this_token.line,
							col = this_token.col,
						}

						if rule.keep then
							--We only want to keep certain tokens of the matched group, not all of them.
							new_token.children = {}
							local i
							for i = 1, #rule.keep do
								table.insert(new_token.children, tokens[index + rule.keep[i] - 1])
							end
						else
							--By default, add all tokens as children.
							local i
							for i = 1, #rule.match do
								table.insert(new_token.children, tokens[index + i - 1])
							end
						end

						return new_token, #rule.match, nil
					end

				end
			end
		end

		--No matches found, so return unexpected token
		return nil, nil, unexpected_token
	end


	local function full_reduce()
		local i = 1
		local new_tokens = {}
		local first_failure = nil
		local did_reduce = false

		while i <= #tokens do
			local new_token
			local consumed_ct
			local failure_index

			new_token, consumed_ct, failure_index = reduce(i)

			if new_token then
				table.insert(new_tokens, new_token)
				did_reduce = true
				i = i + consumed_ct
			else
				if first_failure == nil then
					first_failure = failure_index
				end
				table.insert(new_tokens, tokens[i])
				i = i + 1
			end
		end

		return new_tokens, did_reduce, first_failure
	end

	--Run all syntax rules and condense tokens as far as possible
	while true do
		local new_tokens, did_reduce, first_failure = full_reduce()
		if #new_tokens == 1 then
			return new_tokens
		end

		if not did_reduce then
			local token = tokens[first_failure]
			parse_error(token.line, token.col, 'Unexpected token "'..token.text..'"', file)
		end

		tokens = new_tokens

		for _, t in pairs(tokens) do
			print_tokens_recursive(t)
		end
		print()
	end

	return tokens
end