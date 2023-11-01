local rules = {
	--String Concatenation
	{
		match = {{tok.comparison, tok.array_concat}, {tok.comparison, tok.array_concat}},
		id = tok.concat,
		not_after = {tok.op_assign},
		not_before = {tok.index_open},
		text = '..',
	},

	--Function call
	{
		match = {{tok.text, tok.variable}, {tok.paren_open}, {tok.comparison}, {tok.paren_close}},
		id = tok.func_call,
		keep = {3},
		text = 1,
	},
	{
		match = {{tok.text, tok.variable}, {tok.paren_open}, {tok.paren_close}},
		id = tok.func_call,
		keep = {},
		text = 1,
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
		match = {{tok.lit_number, tok.lit_boolean, tok.lit_null, tok.negate, tok.string, tok.parentheses, tok.func_call, tok.index, tok.expression, tok.inline_command, tok.concat}},
		id = tok.value,
		meta = true,
	},
	{
		match = {{tok.variable}},
		id = tok.value,
		meta = true,
		not_before = {tok.paren_open},
	},

	--Length operator
	{
		match = {{tok.op_count}, {tok.value, tok.comparison}},
		id = tok.length,
		keep = {2},
		text = 1,
		not_before = {tok.paren_open},
	},

	--Unary negation is a bit weird; highest precedence and cannot occur after certain nodes.
	{
		match = {{tok.op_minus}, {tok.value, tok.comparison}},
		id = tok.negate,
		keep = {2},
		text = 1,
		not_after = {tok.lit_number, tok.lit_false, tok.lit_true, tok.lit_null, tok.negate, tok.command_close, tok.expr_close, tok.string_close, tok.string_open, tok.paren_close, tok.inline_command, tok.expression, tok.parentheses},
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
	{
		match = {{tok.array_slice, tok.array_concat, tok.comparison}, {tok.op_comma}},
		id = tok.array_concat,
		keep = {1},
		text = 2,
		not_before = {tok.lit_boolean, tok.lit_null, tok.lit_number, tok.string_open, tok.command_open, tok.expr_open, tok.array_slice, tok.array_concat, tok.comparison, tok.paren_open, tok.index_open, tok.parentheses},
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
		onmatch = function(token)
			if token.text == '~=' then token.text = '!=' end
		end,
	},
	{
		match = {{tok.boolean, tok.length}},
		id = tok.comparison,
		meta = true,
	},

	--Parentheses
	{
		match = {{tok.paren_open}, {tok.comparison}, {tok.paren_close}},
		id = tok.parentheses,
		not_after = {tok.variable},
		keep = {2},
		text = 1,
	},
	{
		match = {{tok.paren_open}, {tok.paren_close}},
		id = tok.parentheses,
		not_after = {tok.variable},
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Parentheses must contain an expression', file)
		end,
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
		match = {{tok.string_open}, {tok.expression, tok.text, tok.inline_command, tok.comparison}},
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
		match = {{tok.text, tok.expression, tok.inline_command, tok.string, tok.comparison}},
		id = tok.command,
		not_after_range = {tok.expr_open, tok.command}, --Command cannot come after anything in this range
		not_after = {tok.kwd_for, tok.kwd_subroutine},
		text = 'cmd',
	},
	{
		match = {{tok.command}, {tok.text, tok.expression, tok.inline_command, tok.string, tok.comparison}},
		append = true,
	},

	--IF block
	{
		match = {{tok.kwd_if}, {tok.command}, {tok.kwd_then}, {tok.command, tok.program, tok.statement}, {tok.kwd_end, tok.elif_stmt, tok.else_stmt}},
		id = tok.if_stmt,
		keep = {2, 4, 5},
		text = 1,
	},
	--ELSE block
	{
		match = {{tok.kwd_else}, {tok.command, tok.program, tok.statement}, {tok.kwd_end}},
		id = tok.else_stmt,
		keep = {2, 4, 6},
		text = 1,
	},
	--ELIF block
	{
		match = {{tok.kwd_elif}, {tok.command}, {tok.kwd_then}, {tok.command, tok.program, tok.statement}, {tok.kwd_end, tok.elif_stmt, tok.else_stmt}},
		id = tok.elif_stmt,
		keep = {2, 4},
		text = 1,
	},

	--WHILE loop
	{
		match = {{tok.kwd_while}, {tok.command}, {tok.kwd_do}, {tok.command, tok.program, tok.statement}, {tok.kwd_end}},
		id = tok.while_stmt,
		keep = {2, 4},
		text = 1,
	},
	{
		match = {{tok.kwd_while}, {tok.command}, {tok.kwd_do}, {tok.kwd_end}},
		id = tok.while_stmt,
		keep = {2},
		text = 1,
	},
	--Invalid while loops
	{
		match = {{tok.kwd_while}, {tok.command}},
		id = tok.while_stmt,
		text = 1,
		not_before = {tok.kwd_do, tok.line_ending, tok.kwd_in, tok.text, tok.expression, tok.string_open, tok.expr_open, tok.command_open, tok.inline_command},
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Incomplete while loop declaration (expected "while . do ... end")', file)
		end,
	},

	--FOR loop
	{
		match = {{tok.kwd_for}, {tok.text}, {tok.kwd_in}, {tok.command, tok.comparison}, {tok.kwd_do}, {tok.command, tok.program, tok.statement}, {tok.kwd_end}},
		id = tok.for_stmt,
		keep = {2, 4, 6},
		text = 1,
	},
	{
		match = {{tok.kwd_for}, {tok.text}, {tok.kwd_in}, {tok.command, tok.comparison}, {tok.kwd_do}, {tok.kwd_end}},
		id = tok.for_stmt,
		keep = {2, 4},
		text = 1,
	},
	{
		match = {{tok.kwd_for}, {tok.text}, {tok.kwd_in}, {tok.command, tok.comparison}, {tok.kwd_do}, {tok.line_ending}, {tok.kwd_end}},
		id = tok.for_stmt,
		keep = {2, 4},
		text = 1,
	},
	--Invalid for loops
	{
		match = {{tok.kwd_for}, {tok.text}, {tok.kwd_in}, {tok.command, tok.comparison}},
		id = tok.for_stmt,
		text = 1,
		not_before = {tok.kwd_do, tok.text, tok.expression, tok.string_open, tok.expr_open, tok.command_open, tok.inline_command},
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Incomplete for loop declaration (expected "for . in . do ... end")', file)
		end,
	},
	{
		match = {{tok.kwd_for}, {tok.text}},
		id = tok.for_stmt,
		text = 1,
		not_before = {tok.kwd_in, tok.text, tok.expression, tok.string_open, tok.expr_open, tok.command_open, tok.inline_command},
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Incomplete for loop declaration (expected "for . in . do ... end")', file)
		end,
	},


	--Delete statement
	{
		match = {{tok.kwd_delete}, {tok.command}},
		id = tok.delete_stmt,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison},
		keep = {2},
		text = 1,
	},

	--SUBROUTINE statement
	{
		match = {{tok.kwd_subroutine}, {tok.label}, {tok.command, tok.program, tok.statement}, {tok.kwd_end}},
		id = tok.subroutine,
		keep = {3},
		text = 2,
	},
	{
		match = {{tok.kwd_subroutine}, {tok.label}, {tok.kwd_end}},
		id = tok.subroutine,
		keep = {},
		text = 2,
	},
	{
		match = {{tok.kwd_subroutine}, {tok.label}, {tok.line_ending}, {tok.kwd_end}},
		id = tok.subroutine,
		keep = {},
		text = 2,
	},

	--Invalid subroutine
	{
		match = {{tok.kwd_subroutine}},
		id = tok.subroutine,
		not_before = {tok.label},
		text = 1,
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Incomplete subroutine declaration (expected "subroutine LABEL: ... end")', file)
		end,
	},

	--GOSUB statement
	{
		match = {{tok.kwd_gosub}, {tok.command}},
		id = tok.gosub_stmt,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison},
		keep = {2},
		text = 1,
	},

	--BREAK statement (can break out of multiple loops)
	{
		match = {{tok.kwd_break}, {tok.command}},
		id = tok.break_stmt,
		keep = {2},
		text = 1,
	},
	{
		match = {{tok.kwd_break}},
		id = tok.break_stmt,
		keep = {},
		text = 1,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison},
	},

	--CONTINUE statement (can continue any parent loop)
	{
		match = {{tok.kwd_continue}, {tok.command}},
		id = tok.continue_stmt,
		keep = {2},
		text = 1,
	},
	{
		match = {{tok.kwd_continue}},
		id = tok.continue_stmt,
		keep = {},
		text = 1,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison},
	},

	--Variable assignment
	{
		match = {{tok.kwd_let}, {tok.var_assign}, {tok.op_assign}, {tok.command, tok.expression, tok.string}},
		id = tok.let_stmt,
		keep = {2, 4},
		text = 1,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison},
	},

	{
		match = {{tok.kwd_let}, {tok.var_assign}},
		id = tok.let_stmt,
		keep = {2},
		text = 1,
		not_before = {tok.op_assign},
	},

	--INVALID variable assignment
	{
		match = {{tok.kwd_let}, {tok.var_assign}, {tok.op_assign}},
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.command},
		onmatch = function(token, file)
			parse_error(token.children[3].line, token.children[3].col, 'Missing expression after variable assignment', file)
		end,
	},

	--Statements
	{
		match = {{tok.if_stmt, tok.while_stmt, tok.for_stmt, tok.let_stmt, tok.delete_stmt, tok.subroutine, tok.gosub_stmt, tok.kwd_return, tok.continue_stmt, tok.kwd_stop, tok.break_stmt}},
		id = tok.statement,
		meta = true,
	},
	{
		match = {{tok.statement}, {tok.line_ending}},
		id = tok.statement,
		meta = true,
	},

	--Full program
	{
		match = {{tok.command, tok.program, tok.statement}, {tok.command, tok.program, tok.statement}},
		id = tok.program,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison},
		text = 'stmt_list',
	},
	{
		match = {{tok.command, tok.program, tok.statement}, {tok.line_ending}},
		id = tok.program,
		meta = true,
	},
	{
		match = {{tok.line_ending}, {tok.command, tok.program, tok.statement}},
		id = tok.program,
		onmatch = function(token)
			--Catch possible dead ends where line endings come before any commands.
			local i, _
			for _, i in ipairs({'text', 'line', 'col', 'id', 'meta_id'}) do
				token[i] = token.children[2][i]
			end
			token.children = token.children[2].children
		end,
	},

	{
		match = {{tok.line_ending}, {tok.line_ending}},
		id = tok.line_ending,
		meta = true,
	},
}

function SyntaxParser(tokens, file)
	if #tokens == 0 then
		parse_error(0, 0, 'Program contains no text', file)
	end

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
				if not rule_failed and rule.not_after_range and index > 1 then
					local prev_token = tokens[index - 1]
					if prev_token.id >= rule.not_after_range[1] and prev_token.id <= rule.not_after_range[2] then
						rule_failed = true
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

				if rule_matches and rule.not_before and (index + #rule.match) <= #tokens then
					local i
					local next_token = tokens[index + #rule.match]
					for i = 1, #rule.not_before do
						if next_token.id == rule.not_before[i] then
							rule_matches = false
							break
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

						if rule.onmatch then
							local tkn = rule.onmatch(new_token, file)
							if tkn ~= nil then new_token = tkn end
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

	local function fold()
		local new_tokens, did_reduce, first_failure = full_reduce()
		if #new_tokens == 1 then
			--Try one final set of reductions!
			local i
			for i = 1, 10 do
				tokens = new_tokens
				new_tokens, did_reduce, first_failure = full_reduce()
				if not did_reduce then break end
			end

			local id = new_tokens[1].id

			if id == tok.line_ending then
				parse_error(1, 1, 'Program contains no actionable text', file)
			end

			if (id ~= tok.command and id < tok.program) or id == tok.else_stmt or id == tok.elif_stmt then
				parse_error(1, 1, 'Unexpected token "'..new_tokens[1].text..'"', file)
			end

			tokens = new_tokens
			return false
		end

		loops_since_reduction = loops_since_reduction + 1

		-- for _, t in pairs(tokens) do
		-- 	print_tokens_recursive(t)
		-- end
		-- print()

		if not did_reduce or loops_since_reduction > 500 then
			if first_failure == nil then
				parse_error(1, 1, 'COMPILER BUG: Max iterations exceeded but no syntax error was found!', file)
			end

			local token = tokens[first_failure]
			parse_error(token.line, token.col, 'Unexpected token "'..token.text..'"', file)
		end

		tokens = new_tokens

		return true
	end

	return {
		fold = fold,
		get = function()
			return tokens
		end
	}
end