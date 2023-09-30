require "tokens"

local rules = {
	--Convert literals / variables into values
	{
		form = {{tok.lit_number, tok.lit_false, tok.lit_true, tok.lit_null, tok.variable}},
		operation = function(tokens)
			tokens[1].meta_id = tok.value
			return tokens[1]
		end
	},

	--Condense multiplication operations
	{
		form = {{tok.value}, {tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod}, {tok.value}},
		operation = function(tokens)
			tokens[2].meta_id = tok.value
			tokens[2].children = {
				tokens[1], tokens[3],
			}
			return tokens[2]
		end
	},

	--Condense addition operations
	{
		form = {{tok.mult, tok.value}, {tok.op_plus, tok.op_minus}, {tok.mult, tok.value}},
		operation = function(tokens)
			tokens[2].meta_id = tok.value
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
	}
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
			token_list, reduced = reduce(token_list, rule.form, rule.operation)
			if reduced then break end
		end

		--If token count did not change after iterating over all rules, then it will never reduce
		if not reduced then break end
	end

	for _, token in pairs(token_list) do
		print_tokens_recursive(token)
	end
end

function reduce(tokens, form, operation)
	local new_tokens = {}
	local i = 1
	local did_reduce = false
	while i <= #tokens do
		if check_match(tokens, i, form) then
			local matched_group = {}
			local k
			for k = i, i + #form do
				table.insert(matched_group, tokens[k])
			end
			table.insert(new_tokens, operation(matched_group))
			did_reduce = true
			i = i + #form
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