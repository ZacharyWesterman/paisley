local rules = {
	--String Concatenation
	{
		match = {{tok.comparison, tok.array_concat}, {tok.comparison, tok.array_concat}},
		id = tok.concat,
		text = 'string concat',
	},

	--Function call
	{
		match = {{tok.comparison}, {tok.paren_open}, {tok.comparison}, {tok.paren_close}},
		id = tok.func_call,
		keep = {1, 3},
		text = 2,
	},

	--Array indexing
	{
		match = {{tok.comparison}, {tok.index_open}, {tok.comparison}, {tok.index_close}},
		id = tok.index,
		keep = {1, 3},
		text = 2,
	},

	--Treat all literals the same.
	{
		match = {{tok.lit_number, tok.lit_false, tok.lit_true, tok.lit_null, tok.negate, tok.variable, tok.string, tok.parentheses, tok.func_call, tok.index, tok.expression, tok.inline_command, tok.concat}},
		id = tok.value,
		meta = true,
	},

	--Unary negation is a bit weird; highest precedence and cannot occur after certain nodes.
	{
		match = {{tok.op_minus}, {tok.value, tok.comparison}},
		id = tok.negate,
		keep = {2},
		text = 1,
		not_after = {tok.lit_number, tok.lit_false, tok.lit_true, tok.lit_null, tok.negate},
	},

	--Multiplication
	{
		match = {{tok.value, tok.multiply, tok.comparison}, {tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod}, {tok.value, tok.multiply, tok.comparison}},
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
		match = {{tok.multiply, tok.add, tok.comparison}, {tok.op_plus, tok.op_minus}, {tok.multiply, tok.add, tok.comparison}},
		id = tok.add,
		keep = {1, 3},
		text = 2,
	},

	--If no other addition was detected, just promote the value to add status.
	--This is to keep add as higher precedence than boolean.
	{
		match = {{tok.multiply}},
		id = tok.add,
		meta = true,
	},

	--Array Slicing
	{
		match = {{tok.add, tok.array_slice, tok.comparison}, {tok.op_slice}, {tok.add, tok.array_slice, tok.comparison}},
		id = tok.array_slice,
		keep = {1, 3},
		text = 2,
	},
	{
		match = {{tok.add}},
		id = tok.array_slice,
		meta = true,
	},

	--Array Concatenation
	{
		match = {{tok.array_slice, tok.array_concat, tok.comparison}, {tok.op_comma}, {tok.array_slice, tok.array_concat, tok.comparison}},
		id = tok.array_concat,
		keep = {1, 3},
		text = 2,
	},
	{
		match = {{tok.array_slice}},
		id = tok.array_concat,
		meta = true,
	},

	--Prefix Boolean not
	{
		match = {{tok.op_not}, {tok.array_concat, tok.boolean, tok.comparison}},
		id = tok.boolean,
		keep = {2},
		text = 1,
	},

	--Postfix Exists operator
	{
		match = {{tok.array_concat, tok.boolean, tok.comparison}, {tok.op_exists}},
		id = tok.boolean,
		keep = {1},
		text = 2,
	},

	--Infix Boolean operators
	{
		match = {{tok.array_concat, tok.boolean, tok.comparison}, {tok.op_and, tok.op_or, tok.op_xor, tok.op_in, tok.op_like}, {tok.array_concat, tok.boolean, tok.comparison}},
		id = tok.boolean,
		keep = {1, 3},
		text = 2,
	},

	--If no other boolean op was detected, just promote the value to bool status.
	--This is to keep booleans as higher precedence than comparison.
	{
		match = {{tok.array_concat}},
		id = tok.boolean,
		meta = true,
	},

	--Logical Comparison
	{
		match = {{tok.boolean, tok.comparison}, {tok.op_ge, tok.op_gt, tok.op_le, tok.op_lt, tok.op_eq, tok.op_ne}, {tok.boolean, tok.comparison}},
		id = tok.comparison,
		keep = {1, 3},
		text = 2,
	},
	{
		match = {{tok.boolean}},
		id = tok.comparison,
		meta = true,
	},

	--Parentheses
	{
		match = {{tok.paren_open}, {tok.comparison}, {tok.paren_close}},
		id = tok.parentheses,
		keep = {2},
		text = 1,
	},

	--Expressions
	{
		match = {{tok.expr_open}, {tok.comparison}, {tok.expr_close}},
		id = tok.expression,
		keep = {2},
		text = 1,
	},


	--Strings
	{
		match = {{tok.string_open}, {tok.expression, tok.text, tok.inline_command}},
		append = true, --This is an "append" token: the first token in the group does not get consumed, instead all other tokens are appended as children.
	},
	{
		match = {{tok.string_open}, {tok.string_close}},
		id = tok.string,
		meta = true,
	},

	--Inline commands
	{
		match = {{tok.command_open}, {tok.command, tok.program}, {tok.command_close}},
		id = tok.inline_command,
		keep = {2},
		text = 1,
	},

	--Commands
	{
		match = {{tok.text, tok.expression, tok.inline_command, tok.string}},
		id = tok.command,
		not_after = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_close, tok.command_close, tok.string_close},
		text = 'cmd',
	},
	{
		match = {{tok.command}, {tok.text, tok.expression, tok.inline_command, tok.string}},
		append = true,
	},

	--Full program
	{
		match = {{tok.command, tok.program}, {tok.command, tok.program}},
		id = tok.program,
		text = 'stmt_list',
	},
	{
		match = {{tok.command}, {tok.line_ending}},
		id = tok.program,
		meta = true,
	},
}

function syntax(tokens, file)

	local function matches(index, rule, rule_index)
		local this_token = tokens[index]
		local group = rule.match[rule_index]

		local _
		local _t
		for _, _t in ipairs(group) do
			if (this_token.meta_id == nil and this_token.id == _t) or (this_token.meta_id == _t) then
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
					if rule.meta then
						--This is a "meta" rule. It reduces a token by just changing the id.
						this_token.meta_id = rule.id
						return this_token, #rule.match, nil
					elseif rule.append then
						--This is an "append" token: the first token in the group does not get consumed, instead all other tokens are appended as children.
						if this_token.children == nil then this_token.children = {} end

						local i
						for i = 2, #rule.match do
							table.insert(this_token.children, tokens[index + i - 1])
						end

						return this_token, #rule.match, nil
					else
						local text = '<undefined>'
						if rule.text ~= nil then
							if type(rule.text) == 'string' then
								text = rule.text
							else
								text = tokens[index + rule.text - 1].text
							end
						end

						local new_token = {
							text = text,
							id = rule.id,
							line = this_token.line,
							col = this_token.col,
							children = {},
						}

						if rule.keep then
							--We only want to keep certain tokens of the matched group, not all of them.
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
	local loops_since_reduction = 0

	while true do
		local new_tokens, did_reduce, first_failure = full_reduce()
		if #new_tokens == 1 then
			return new_tokens
		end

		loops_since_reduction = loops_since_reduction + 1

		if not did_reduce or loops_since_reduction > 50 then
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