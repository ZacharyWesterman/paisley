require "tokens"

local rules = {
	--Condense array indexing
	{
		form = {{tok.value}, {tok.index_open}, {tok.value}, {tok.index_close}},
		operation = function(tokens)
			tokens[2].meta_id = tok.value
			tokens[2].id = tok.index
			tokens[2].children = { tokens[1], tokens[3] }
			return tokens[2]
		end
	},

	--Convert literals / variables into values
	{
		form = {{tok.lit_number, tok.lit_false, tok.lit_true, tok.lit_null, tok.variable}},
		operation = function(tokens)
			tokens[1].meta_id = tok.value
			return tokens[1]
		end
	},

	--Condense unary negate operation
	{
		form = {{tok.op_minus}, {tok.value}},
		not_after = {tok.lit_number, tok.literal, tok.paren_close, tok.expr_close, tok.index_close},
		operation = function(tokens)
			tokens[1].meta_id = tok.value
			tokens[1].id = tok.negate
			tokens[1].children = {
				tokens[2],
			}
			return tokens[1]
		end
	},

	--Condense array-slice operations
	{
		form = {{tok.value}, {tok.op_slice}, {tok.value}},
		operation = function(tokens)
			tokens[2].meta_id = tok.value
			tokens[2].id = tok.array_slice
			tokens[2].children = {
				tokens[1], tokens[3],
			}
			return tokens[2]
		end
	},

	--Condense multiplication operations
	{
		form = {{tok.value}, {tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod}, {tok.value}},
		operation = function(tokens)
			tokens[2].meta_id = tok.value
			tokens[2].id = tok.multiply
			tokens[2].children = {
				tokens[1], tokens[3],
			}
			return tokens[2]
		end
	},

	--Condense addition operations
	{
		form = {{tok.value}, {tok.op_plus, tok.op_minus}, {tok.value}},
		operation = function(tokens)
			tokens[2].meta_id = tok.value
			tokens[2].id = tok.add
			tokens[2].children = {
				tokens[1], tokens[3],
			}
			return tokens[2]
		end
	},

	--Condense unary boolean operations
	{
		form = {{tok.op_not}, {tok.value}},
		operation = function(tokens)
			tokens[1].meta_id = tok.value
			tokens[1].id = tok.boolean
			tokens[1].children = {
				tokens[2],
			}
			return tokens[1]
		end
	},

	--Condense binary boolean operations
	{
		form = {{tok.value}, {tok.op_and, tok.op_or, tok.op_xor}, {tok.value}},
		operation = function(tokens)
			tokens[2].meta_id = tok.value
			tokens[2].id = tok.boolean
			tokens[2].children = {
				tokens[1], tokens[3],
			}
			return tokens[2]
		end
	},

	--Condense comparison operations
	{
		form = {{tok.value}, {tok.op_eq, tok.op_ne, tok.op_gt, tok.op_ge, tok.op_lt, tok.op_le}, {tok.value}},
		operation = function(tokens)
			tokens[2].meta_id = tok.value
			tokens[2].id = tok.comparison
			tokens[2].children = {
				tokens[1], tokens[3],
			}
			return tokens[2]
		end
	},

	--Condense array-concat operations
	{
		form = {{tok.value}, {tok.op_comma}, {tok.value}},
		operation = function(tokens)
			tokens[2].meta_id = tok.value
			tokens[2].id = tok.array_concat
			tokens[2].children = {
				tokens[1], tokens[3],
			}
			return tokens[2]
		end
	},

	--Condense parentheses-enclosed expressions
	{
		form = {{tok.paren_open}, {tok.value}, {tok.paren_close}},
		operation = function(tokens)
			return tokens[2]
		end
	},

	--Condense expression patterns
	{
		form = {{tok.expr_open}, {tok.value}, {tok.expr_close}},
		operation = function(tokens)
			tokens[1].id = tok.expression
			tokens[1].meta_id = tok.value
			tokens[1].children = {tokens[2]}
			return tokens[1]
		end
	},
}

--[[
Generate AST from a table or iterator of tokens.
--]]
function syntax(tokens)
	--Treat tables the same as iterators
	local _
	local token_list = tokens
	if type(tokens) ~= 'table' then
		token_list = {}
		local token
		for _, token in tokens do
			table.insert(token_list, token)
		end
	end

	local rule
	local token_count = #token_list
	while true do
		local reduced = false
		for _, rule in ipairs(rules) do
			token_list, reduced = reduce(token_list, rule.form, rule.operation, rule.not_after)
			if reduced then break end
		end

		--If token count did not change after iterating over all rules, then it will never reduce
		if not reduced then break end
	end

	for _, token in pairs(token_list) do
		print_tokens_recursive(token)
	end
end

function reduce(tokens, form, operation, not_after)
	local new_tokens = {}
	local i = 1
	local did_reduce = false
	while i <= #tokens do
		if check_match(tokens, i, form) then
			local reject = false
			if not_after and (i > 1) then
				local _
				local t
				for _, t in pairs(not_after) do
					if tokens[i-1].id == t or tokens[i-1].meta_id == t then
						reject = true
						break
					end
				end
			end

			if reject then
				table.insert(new_tokens, tokens[i])
				i = i + 1
			else
				local matched_group = {}
				local k
				for k = i, i + #form do
					table.insert(matched_group, tokens[k])
				end
				table.insert(new_tokens, operation(matched_group))
				did_reduce = true
				i = i + #form
			end
		else
			table.insert(new_tokens, tokens[i])
			i = i + 1
		end
	end

	return new_tokens, did_reduce
end

function check_match(tokens, index, form)
	local form_rule
	local i
	local _
	local accepted_token_id

	for i, form_rule in ipairs(form) do
		local this_token = tokens[index + i - 1]

		if this_token == nil then return false end --Definitely not a match if we ran out of tokens

		local valid = false
		for _, accepted_token_id in ipairs(form_rule) do
			if (this_token.meta_id == nil and accepted_token_id == this_token.id) or (accepted_token_id == this_token.meta_id) then
				valid = true
				break
			end
		end

		if not valid then return false end
	end

	return true
end