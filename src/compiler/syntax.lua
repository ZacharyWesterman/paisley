local function _match_stmt_onmatch(token, file)
	local if_ct = 0

	local function check_nodes(node)
		if node.id == TOK.program then
			for i = 1, #node.children do
				check_nodes(node.children[i])
			end
		elseif node.id ~= TOK.if_stmt then
			parse_error(node.span, 'Top level of `match` statement can only contain `if` statements', file)
		else
			if_ct = if_ct + 1
			if node.children[3].id ~= TOK.kwd_end then
				parse_error(node.children[3].span,
					'Extra conditional branch does not make sense inside a `match` statement', file)
			end
		end
	end

	if token.children[2].id ~= TOK.kwd_match then check_nodes(token.children[2]) end
end

local rules = {
	--Function call, dot-notation
	{
		match = { { TOK.value, TOK.comparison, TOK.func_call }, { TOK.op_dot }, { TOK.value, TOK.func_call, TOK.comparison } },
		id = TOK.func_call,
		text = 3,
		not_after = { TOK.op_dot, TOK.op_slice },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			local c3 = token.children[3]
			local c1 = token.children[1]

			if c3.id == TOK.variable then
				--Dot notation using variable names is just indexing with strings.
				c3.id = TOK.text
				c3.value = c3.text

				return {
					id = TOK.index,
					span = Span:merge(c1.span, c3.span),
					text = '.',
					children = { c1, {
						id = TOK.string_open,
						text = '\'',
						span = c3.span,
						children = { c3 },
					} },
				}
			elseif c3.id == TOK.func_call then
				table.insert(c3.children, 1, c1)
				token.children = c3.children
				token.span = c3.span
			else
				parse_error(token.children[2].span, 'Expected function name or object key after dot operator', file)
			end
		end,
	},

	--String Concatenation
	{
		match = { { TOK.comparison, TOK.array_concat }, { TOK.comparison, TOK.array_concat } },
		id = TOK.concat,
		not_after = { TOK.op_assign, TOK.string_close, TOK.text, TOK.op_dot, TOK.comparison, TOK.line_ending },
		not_before = { TOK.index_open },
		expr_only = true,
		text = '..',
	},

	--Empty expressions (ERROR)
	{
		match = { { TOK.expr_open }, { TOK.expr_close } },
		not_after = { TOK.var_assign },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span, 'Expression has no body', file)
		end,
	},
	--Empty command (ERROR)
	{
		match = { { TOK.command_open }, { TOK.command_close } },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span, 'Inline command evaluation has no body', file)
		end,
	},

	--Function call
	{
		match = { { TOK.text, TOK.variable }, { TOK.paren_open }, { TOK.comparison }, { TOK.paren_close } },
		id = TOK.func_call,
		keep = { 3 },
		text = 1,
	},
	{
		match = { { TOK.text, TOK.variable }, { TOK.paren_open }, { TOK.paren_close } },
		id = TOK.func_call,
		keep = {},
		text = 1,
	},

	--Special "reduce" function call
	{
		match = { { TOK.text, TOK.variable }, { TOK.paren_open }, { TOK.comparison }, { TOK.op_comma }, { TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_idiv, TOK.op_div, TOK.op_mod, TOK.op_and, TOK.op_or, TOK.op_xor, TOK.op_ge, TOK.op_gt, TOK.op_le, TOK.op_lt, TOK.op_eq, TOK.op_ne }, { TOK.paren_close } },
		id = TOK.func_call,
		keep = { 3, 5 },
		text = 1,
	},
	--Special "reduce", function call (for dot notation)
	{
		match = { { TOK.text, TOK.variable }, { TOK.paren_open }, { TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_idiv, TOK.op_div, TOK.op_mod, TOK.op_and, TOK.op_or, TOK.op_xor, TOK.op_ge, TOK.op_gt, TOK.op_le, TOK.op_lt, TOK.op_eq, TOK.op_ne }, { TOK.paren_close } },
		id = TOK.func_call,
		keep = { 3 },
		text = 1,
	},

	--Array indexing
	{
		match = { { TOK.comparison }, { TOK.index_open }, { TOK.comparison }, { TOK.index_close } },
		id = TOK.index,
		keep = { 1, 3 },
		text = 2,
		not_after = { TOK.op_dot },
	},

	--Treat all literals the same.
	{
		match = { { TOK.lit_number, TOK.lit_boolean, TOK.lit_null, TOK.negate, TOK.string, TOK.parentheses, TOK.func_call, TOK.index, TOK.expression, TOK.inline_command, TOK.concat, TOK.macro, TOK.macro_ref, TOK.ternary, TOK.list_comp, TOK.key_value_pair } },
		id = TOK.value,
		meta = true,
	},
	{
		match = { { TOK.variable } },
		id = TOK.value,
		meta = true,
		not_before = { TOK.paren_open },
		not_after = { TOK.kwd_for_expr },
	},

	--Length operator
	{
		match = { { TOK.op_count }, { TOK.value, TOK.comparison } },
		id = TOK.length,
		keep = { 2 },
		text = 1,
		not_before = { TOK.paren_open, TOK.op_dot },
	},

	--Unary negation is a bit weird; highest precedence and cannot occur after certain nodes.
	{
		match = { { TOK.op_minus }, { TOK.value, TOK.comparison } },
		id = TOK.negate,
		keep = { 2 },
		text = 1,
		not_after = { TOK.lit_number, TOK.lit_boolean, TOK.lit_null, TOK.negate, TOK.command_close, TOK.expr_close, TOK.string_close, TOK.string_open, TOK.paren_close, TOK.inline_command, TOK.expression, TOK.parentheses, TOK.variable, TOK.func_call, TOK.index_close, TOK.index },
		not_before = { TOK.op_dot },
	},

	--Exponentiation
	{
		match = { { TOK.value, TOK.exponent, TOK.comparison }, { TOK.op_exponent }, { TOK.value, TOK.comparison } },
		id = TOK.exponent,
		not_after = { TOK.op_exponent, TOK.op_dot },
		keep = { 1, 3 },
		text = 2,
		not_before = { TOK.op_dot },
	},

	--If no other exponent was detected, just promote the value.
	--This is to keep exponent as higher precedence than multiplication.
	{
		match = { { TOK.value } },
		id = TOK.multiply,
		meta = true,
	},

	--Multiplication
	{
		match = { { TOK.value, TOK.multiply, TOK.comparison }, { TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod }, { TOK.value, TOK.multiply, TOK.comparison } },
		id = TOK.multiply,
		not_before = { TOK.op_dot, TOK.op_exponent, TOK.op_slice },
		not_after = { TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_dot, TOK.op_exponent, TOK.op_slice },
		keep = { 1, 3 },
		text = 2,
	},

	--If no other multiplication was detected, just promote the value to mult status.
	--This is to keep mult as higher precedence than addition.
	{
		match = { { TOK.value } },
		id = TOK.multiply,
		meta = true,
		not_before = { TOK.op_dot },
	},

	--Addition (lower precedence than multiplication)
	{
		match = { { TOK.exponent, TOK.multiply, TOK.add, TOK.comparison }, { TOK.op_plus, TOK.op_minus }, { TOK.exponent, TOK.multiply, TOK.add, TOK.comparison } },
		id = TOK.add,
		not_before = { TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_dot, TOK.op_exponent, TOK.op_slice },
		not_after = { TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_dot, TOK.op_exponent, TOK.op_slice },
		keep = { 1, 3 },
		text = 2,
	},

	--If no other addition was detected, just promote the value to add status.
	--This is to keep add as higher precedence than boolean.
	{
		match = { { TOK.exponent, TOK.multiply } },
		id = TOK.add,
		meta = true,
	},

	--Array Slicing
	{
		match = { { TOK.add, TOK.array_slice, TOK.comparison }, { TOK.op_slice }, { TOK.add, TOK.array_slice, TOK.comparison } },
		id = TOK.array_slice,
		keep = { 1, 3 },
		text = 2,
		not_before = { TOK.index_open },
	},
	{ --non-terminated array slicing
		match = { { TOK.add, TOK.array_slice, TOK.comparison }, { TOK.op_slice }, { TOK.op_slice } },
		id = TOK.array_slice,
		keep = { 1 },
		text = 2,
	},
	{
		match = { { TOK.add } },
		id = TOK.array_slice,
		meta = true,
	},

	--Array Concatenation
	{
		match = { { TOK.array_slice, TOK.array_concat, TOK.comparison }, { TOK.op_comma }, { TOK.array_slice, TOK.array_concat, TOK.comparison } },
		id = TOK.array_concat,
		keep = { 1, 3 },
		text = 2,
		not_before = { TOK.index_open, TOK.op_arrow, TOK.op_dot, TOK.kwd_if_expr, TOK.kwd_for_expr },
		not_after = { TOK.op_dot, TOK.op_arrow, TOK.op_in, TOK.kwd_else_expr, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_plus, TOK.op_minus, TOK.op_exponent },
	},
	{
		match = { { TOK.array_slice } },
		id = TOK.array_concat,
		meta = true,
	},
	{
		match = { { TOK.array_slice, TOK.array_concat, TOK.comparison }, { TOK.op_comma } },
		id = TOK.array_concat,
		keep = { 1 },
		text = 2,
		not_before = { TOK.lit_boolean, TOK.lit_null, TOK.lit_number, TOK.string_open, TOK.command_open, TOK.expr_open, TOK.array_slice, TOK.array_concat, TOK.comparison, TOK.paren_open, TOK.index_open, TOK.parentheses, TOK.variable, TOK.func_call, TOK.index, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_idiv, TOK.op_div, TOK.op_mod, TOK.op_and, TOK.op_or, TOK.op_xor, TOK.op_ge, TOK.op_gt, TOK.op_le, TOK.op_lt, TOK.op_eq, TOK.op_ne, TOK.op_arrow, TOK.key_value_pair },
		not_after = { TOK.op_arrow, TOK.op_dot, TOK.op_in, TOK.kwd_else_expr, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_plus, TOK.op_minus, TOK.op_exponent },
	},
	{
		match = { { TOK.op_comma } },
		id = TOK.array_concat,
		keep = {},
		text = 1,
		only_after = { TOK.expr_open, TOK.paren_open },
	},

	--Object definitions, key-value pairs
	{
		match = { { TOK.comparison }, { TOK.op_arrow }, { TOK.comparison } },
		id = TOK.key_value_pair,
		keep = { 1, 3 },
		text = 2,
		not_before = { TOK.lit_boolean, TOK.lit_null, TOK.lit_number, TOK.string_open, TOK.command_open, TOK.expr_open, TOK.array_slice, TOK.array_concat, TOK.comparison, TOK.paren_open, TOK.index_open, TOK.parentheses, TOK.variable, TOK.func_call, TOK.index, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_idiv, TOK.op_div, TOK.op_mod, TOK.op_and, TOK.op_or, TOK.op_xor, TOK.op_ge, TOK.op_gt, TOK.op_le, TOK.op_lt, TOK.op_eq, TOK.op_ne, TOK.kwd_for_expr, TOK.kwd_if_expr, TOK.op_dot },
	},
	{
		match = { { TOK.op_arrow } },
		id = TOK.key_value_pair,
		keep = {},
		text = 1,
		only_after = { TOK.op_comma, TOK.expr_open, TOK.paren_open },
	},

	--Prefix Boolean not
	{
		match = { { TOK.op_not }, { TOK.array_concat, TOK.boolean, TOK.comparison } },
		id = TOK.boolean,
		keep = { 2 },
		text = 1,
	},

	--Postfix Exists operator
	{
		match = { { TOK.array_concat, TOK.boolean, TOK.comparison }, { TOK.op_exists } },
		id = TOK.boolean,
		keep = { 1 },
		text = 2,
	},

	--Infix Boolean operators
	{
		match = { { TOK.array_concat, TOK.boolean, TOK.comparison }, { TOK.op_and, TOK.op_or, TOK.op_xor, TOK.op_in, TOK.op_like }, { TOK.array_concat, TOK.boolean, TOK.comparison } },
		id = TOK.boolean,
		keep = { 1, 3 },
		text = 2,
		not_after = { TOK.op_dot, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_eq, TOK.op_ne, TOK.op_gt, TOK.op_ge, TOK.op_lt, TOK.op_le },
		not_before = { TOK.index_open, TOK.op_dot, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_eq, TOK.op_ne, TOK.op_gt, TOK.op_ge, TOK.op_lt, TOK.op_le },
	},
	{
		match = { { TOK.array_concat, TOK.boolean, TOK.comparison }, { TOK.op_in }, { TOK.array_concat, TOK.boolean, TOK.comparison } },
		id = TOK.boolean,
		keep = { 1, 3 },
		text = 2,
		not_after = { TOK.kwd_for_expr, TOK.op_dot },
		not_before = { TOK.op_dot, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod },
	},

	--Special "{value not in array}" syntax
	{
		match = { { TOK.array_concat, TOK.boolean, TOK.comparison }, { TOK.op_not }, { TOK.op_and, TOK.op_or, TOK.op_xor, TOK.op_in, TOK.op_like }, { TOK.array_concat, TOK.boolean, TOK.comparison } },
		id = TOK.boolean,
		keep = { 1, 4 },
		text = 3,
		not_after = { TOK.op_dot, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_eq, TOK.op_ne, TOK.op_gt, TOK.op_ge, TOK.op_lt, TOK.op_le },
		not_before = { TOK.index_open, TOK.op_dot, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_eq, TOK.op_ne, TOK.op_gt, TOK.op_ge, TOK.op_lt, TOK.op_le },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			return {
				text = 'not',
				id = TOK.boolean,
				span = token.span,
				children = { token },
			}
		end,
	},

	--List comprehension
	{
		match = { { TOK.comparison }, { TOK.kwd_for_expr }, { TOK.variable }, { TOK.op_in }, { TOK.comparison } },
		id = TOK.list_comp,
		keep = { 1, 3, 5 },
		text = 2,
		not_before = { TOK.kwd_if_expr, TOK.op_dot },
	},
	{
		match = { { TOK.comparison }, { TOK.kwd_for_expr }, { TOK.variable }, { TOK.op_in }, { TOK.comparison }, { TOK.kwd_if_expr }, { TOK.comparison } },
		id = TOK.list_comp,
		keep = { 1, 3, 5, 7 },
		text = 2,
		not_before = { TOK.kwd_else_expr, TOK.op_dot, TOK.index_open, TOK.op_dot, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod, TOK.op_eq, TOK.op_ne, TOK.op_gt, TOK.op_ge, TOK.op_lt, TOK.op_le },
	},

	--If no other boolean op was detected, just promote the value to bool status.
	--This is to keep booleans as higher precedence than comparison.
	{
		match = { { TOK.array_concat } },
		id = TOK.boolean,
		meta = true,
	},

	--Logical Comparison
	{
		match = { { TOK.boolean, TOK.comparison }, { TOK.op_ge, TOK.op_gt, TOK.op_le, TOK.op_lt, TOK.op_eq, TOK.op_ne }, { TOK.boolean, TOK.comparison } },
		id = TOK.comparison,
		keep = { 1, 3 },
		text = 2,
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			if token.text == '~=' then token.text = '!=' end
			if token.text == '=' then token.text = '==' end
		end,
		not_after = { TOK.op_dot, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod },
	},
	--Special logical comparison with only an RHS operand.
	--This is only for use in "match" statements,
	--where the LHS operand is implied to be the match expression.
	{
		match = { { TOK.expr_open }, { TOK.op_ge, TOK.op_gt, TOK.op_le, TOK.op_lt, TOK.op_eq, TOK.op_ne, TOK.op_like }, { TOK.boolean, TOK.comparison }, { TOK.expr_close } },
		id = TOK.comparison,
		keep = { 3 },
		text = 2,
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			if token.text == '~=' then token.text = '!=' end
			if token.text == '=' then token.text = '==' end
		end,
	},
	{
		match = { { TOK.boolean, TOK.length } },
		id = TOK.comparison,
		meta = true,
	},

	--Parentheses
	{
		match = { { TOK.paren_open }, { TOK.comparison }, { TOK.paren_close } },
		id = TOK.parentheses,
		not_after = { TOK.variable },
		keep = { 2 },
		text = 1,
	},
	{
		match = { { TOK.paren_open }, { TOK.paren_close } },
		id = TOK.parentheses,
		not_after = { TOK.variable },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span, 'Parentheses must contain an expression', file)
		end,
	},

	--Expressions
	{
		match = { { TOK.expr_open }, { TOK.comparison }, { TOK.expr_close } },
		id = TOK.expression,
		keep = { 2 },
		text = 1,
	},


	--Strings
	{
		match = { { TOK.string_open }, { TOK.expression, TOK.text, TOK.inline_command, TOK.comparison } },
		append = true, --This is an "append" token: the first token in the group does not get consumed, instead all other tokens are appended as children.
	},
	{
		match = { { TOK.string_open }, { TOK.string_close } },
		id = TOK.string,
		meta = true,
	},

	--Inline commands
	{
		match = { { TOK.command_open }, { TOK.command, TOK.program, TOK.statement }, { TOK.command_close } },
		id = TOK.inline_command,
		keep = { 2 },
		text = 1,
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			if token.children[1].id ~= TOK.command and token.children[1].id ~= TOK.gosub_stmt then
				parse_error(token.span,
					'Malformed statement inside command eval block. Must be a single command or gosub', file)
			end
		end,
	},

	--Commands
	{
		match = { { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.comparison } },
		id = TOK.command,
		not_after_range = { TOK.expr_open, TOK.command }, --Command cannot come after anything in this range
		not_after = { TOK.kwd_for, TOK.kwd_subroutine, TOK.kwd_if_expr, TOK.kwd_else_expr, TOK.var_assign, TOK.kwd_match, TOK.kwd_cache, TOK.kwd_using, TOK.kwd_as, TOK.kwd_catch },
		text = 'cmd',
	},
	{
		match = { { TOK.command }, { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.comparison } },
		append = true,
	},

	--IF block
	{
		match = { { TOK.kwd_if }, { TOK.command, TOK.gosub_stmt }, { TOK.kwd_then }, { TOK.command, TOK.program, TOK.statement }, { TOK.kwd_end, TOK.elif_stmt, TOK.else_stmt } },
		id = TOK.if_stmt,
		keep = { 2, 4, 5 },
		text = 1,
	},
	{
		match = { { TOK.kwd_if }, { TOK.command, TOK.gosub_stmt }, { TOK.kwd_then }, { TOK.kwd_end, TOK.elif_stmt, TOK.else_stmt } },
		id = TOK.if_stmt,
		keep = { 2, 3, 4 },
		text = 1,
	},
	{
		match = { { TOK.kwd_if }, { TOK.command, TOK.gosub_stmt }, { TOK.else_stmt } },
		id = TOK.if_stmt,
		keep = { 2, 1, 3 },
		text = 1,
		onmatch = function(token, file)
			token.children[2].id = TOK.kwd_then
		end,
	},
	{ --Invalid if
		match = { { TOK.kwd_if }, { TOK.command, TOK.gosub_stmt } },
		id = TOK.if_stmt,
		text = 1,
		not_before = { TOK.kwd_then, TOK.line_ending, TOK.kwd_else, TOK.else_stmt },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span, 'Missing "then" or "else" after if statement', file)
		end,
	},
	--ELSE block
	{
		match = { { TOK.kwd_else }, { TOK.command, TOK.program, TOK.statement }, { TOK.kwd_end } },
		id = TOK.else_stmt,
		keep = { 2 },
		text = 1,
	},
	{ --Empty else block
		match = { { TOK.kwd_else }, { TOK.kwd_end } },
		id = TOK.else_stmt,
		keep = {},
		text = 1,
	},
	--ELIF block
	{
		match = { { TOK.kwd_elif }, { TOK.command }, { TOK.kwd_then }, { TOK.command, TOK.program, TOK.statement }, { TOK.kwd_end, TOK.elif_stmt, TOK.else_stmt } },
		id = TOK.elif_stmt,
		keep = { 2, 4, 5 },
		text = 1,
	},
	{
		match = { { TOK.kwd_elif }, { TOK.command }, { TOK.kwd_then }, { TOK.kwd_end, TOK.elif_stmt, TOK.else_stmt } },
		id = TOK.elif_stmt,
		keep = { 2, 3, 4 },
		text = 1,
	},
	{ --Invalid elif
		match = { { TOK.kwd_elif }, { TOK.command } },
		id = TOK.if_stmt,
		text = 1,
		not_before = { TOK.kwd_then, TOK.line_ending },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span, 'Missing "then" after elif statement', file)
		end,
	},

	--WHILE loop
	{
		match = { { TOK.kwd_while }, { TOK.command }, { TOK.kwd_do }, { TOK.command, TOK.program, TOK.statement }, { TOK.kwd_end } },
		id = TOK.while_stmt,
		keep = { 2, 4 },
		text = 1,
	},
	{
		match = { { TOK.kwd_while }, { TOK.command }, { TOK.kwd_do }, { TOK.kwd_end } },
		id = TOK.while_stmt,
		keep = { 2 },
		text = 1,
	},
	--Invalid while loops
	{
		match = { { TOK.kwd_while }, { TOK.command } },
		id = TOK.while_stmt,
		text = 1,
		not_before = { TOK.kwd_do, TOK.line_ending, TOK.kwd_in, TOK.text, TOK.expression, TOK.string_open, TOK.expr_open, TOK.command_open, TOK.inline_command },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span, 'Incomplete while loop declaration (expected "while . do ... end")', file)
		end,
	},

	--FOR loop
	{
		match = { { TOK.kwd_for }, { TOK.text }, { TOK.kwd_in }, { TOK.command, TOK.comparison }, { TOK.kwd_do }, { TOK.command, TOK.program, TOK.statement }, { TOK.kwd_end } },
		id = TOK.for_stmt,
		keep = { 2, 4, 6 },
		text = 1,
	},
	{
		match = { { TOK.kwd_for }, { TOK.text }, { TOK.kwd_in }, { TOK.command, TOK.comparison }, { TOK.kwd_do }, { TOK.kwd_end } },
		id = TOK.for_stmt,
		keep = { 2, 4 },
		text = 1,
	},
	{
		match = { { TOK.kwd_for }, { TOK.text }, { TOK.kwd_in }, { TOK.command, TOK.comparison }, { TOK.kwd_do }, { TOK.line_ending }, { TOK.kwd_end } },
		id = TOK.for_stmt,
		keep = { 2, 4 },
		text = 1,
	},
	--Key/Value for loop
	{
		match = { { TOK.kwd_for }, { TOK.text }, { TOK.text }, { TOK.kwd_in }, { TOK.command, TOK.comparison }, { TOK.kwd_do }, { TOK.command, TOK.program, TOK.statement }, { TOK.kwd_end } },
		id = TOK.kv_for_stmt,
		keep = { 2, 3, 5, 7 },
		text = 1,
	},
	{
		match = { { TOK.kwd_for }, { TOK.text }, { TOK.text }, { TOK.kwd_in }, { TOK.command, TOK.comparison }, { TOK.kwd_do }, { TOK.kwd_end } },
		id = TOK.kv_for_stmt,
		keep = { 2, 3, 5 },
		text = 1,
	},
	{
		match = { { TOK.kwd_for }, { TOK.text }, { TOK.text }, { TOK.kwd_in }, { TOK.command, TOK.comparison }, { TOK.kwd_do }, { TOK.line_ending }, { TOK.kwd_end } },
		id = TOK.kv_for_stmt,
		keep = { 2, 3, 5 },
		text = 1,
	},

	--Invalid for loops
	{
		match = { { TOK.kwd_for }, { TOK.text }, { TOK.kwd_in }, { TOK.command, TOK.comparison } },
		id = TOK.for_stmt,
		text = 1,
		not_before = { TOK.kwd_do, TOK.text, TOK.expression, TOK.string_open, TOK.expr_open, TOK.command_open, TOK.inline_command },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span, 'Incomplete for loop declaration (expected "for . in . do ... end")', file)
		end,
	},
	{
		match = { { TOK.kwd_for }, { TOK.text } },
		id = TOK.for_stmt,
		text = 1,
		not_before = { TOK.kwd_in, TOK.text, TOK.expression, TOK.string_open, TOK.expr_open, TOK.command_open, TOK.inline_command },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span, 'Incomplete for loop declaration (expected "for . in . do ... end")', file)
		end,
	},


	--Delete statement
	{
		match = { { TOK.kwd_delete }, { TOK.command } },
		id = TOK.delete_stmt,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
		keep = { 2 },
		text = 1,
	},

	--SUBROUTINE statement
	{
		match = { { TOK.kwd_subroutine }, { TOK.text } },
		id = TOK.subroutine_label,
		text = 2,
		onmatch = function(token, file)
			token.children[2].id = token.id
			return token.children[2]
		end,
	},
	{
		match = { { TOK.subroutine_label }, { TOK.command, TOK.program, TOK.statement }, { TOK.kwd_end } },
		id = TOK.subroutine,
		keep = { 2 },
		text = 1,
	},
	{
		match = { { TOK.subroutine_label }, { TOK.kwd_end } },
		id = TOK.subroutine,
		keep = {},
		text = 1,
	},
	{
		match = { { TOK.subroutine_label }, { TOK.line_ending }, { TOK.kwd_end } },
		id = TOK.subroutine,
		keep = {},
		text = 1,
	},

	--Add CACHE flag to subroutines
	{
		match = { { TOK.kwd_cache }, { TOK.subroutine } },
		id = TOK.subroutine,
		text = 2,
		onmatch = function(token, file)
			if token.children[2].memoize then
				parse_error(token.children[1].span,
					'Subroutine is already memoized; multiple uses of `cache` don\'t make sense',
					file)
			end

			token.children[2].memoize = true
			return token.children[2]
		end,
	},

	--Invalid subroutine
	{
		match = { { TOK.kwd_subroutine } },
		id = TOK.subroutine,
		not_before = { TOK.text },
		text = 1,
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span, 'Incomplete subroutine declaration (expected "subroutine LABEL ... end")', file)
		end,
	},

	--GOSUB statement
	{
		match = { { TOK.kwd_gosub }, { TOK.command } },
		id = TOK.gosub_stmt,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
		keep = { 2 },
		text = 1,
	},

	--BREAK statement (can break out of multiple loops)
	{
		match = { { TOK.kwd_break }, { TOK.command } },
		id = TOK.break_stmt,
		keep = { 2 },
		text = 1,
	},
	{
		match = { { TOK.kwd_break } },
		id = TOK.break_stmt,
		keep = {},
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison, TOK.kwd_cache },
	},
	--Manually delete cache for memoized subroutines
	--Add CACHE flag to subroutines
	{
		match = { { TOK.kwd_break }, { TOK.kwd_cache }, { TOK.text } },
		id = TOK.uncache_stmt,
		keep = { 3 },
		text = 'break cache',
	},

	--CONTINUE statement (can continue any parent loop)
	{
		match = { { TOK.kwd_continue }, { TOK.command } },
		id = TOK.continue_stmt,
		keep = { 2 },
		text = 1,
	},
	{
		match = { { TOK.kwd_continue } },
		id = TOK.continue_stmt,
		keep = {},
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
	},

	--Variable assignment
	{
		match = { { TOK.kwd_let }, { TOK.var_assign }, { TOK.op_assign }, { TOK.command, TOK.expression, TOK.string } },
		id = TOK.let_stmt,
		keep = { 2, 4 },
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
	},
	{
		match = { { TOK.kwd_let }, { TOK.var_assign } },
		id = TOK.let_stmt,
		keep = { 2 },
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison, TOK.op_assign, TOK.var_assign },
	},
	--Assign multiple variables at the same time
	{
		match = { { TOK.var_assign }, { TOK.var_assign } },
		id = TOK.var_assign,
		text = 1,
		keep = { 1, 2 },
		not_after = { TOK.var_assign },
		onmatch = function(token, file)
			local t = token.children[1]
			if t.children == nil then t.children = {} end
			table.insert(t.children, token.children[2])
			return token.children[1]
		end,
	},

	--Variable initialization
	{
		match = { { TOK.kwd_initial }, { TOK.var_assign }, { TOK.op_assign }, { TOK.command, TOK.expression, TOK.string } },
		id = TOK.let_stmt,
		keep = { 2, 4 },
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
	},
	{
		match = { { TOK.kwd_initial }, { TOK.var_assign } },
		id = TOK.let_stmt,
		keep = { 2 },
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison, TOK.op_assign },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.span,
				'Incomplete variable initialization, `' .. token.children[1].text .. '` must have a value', file)
		end,
	},

	--SUB variable assignment
	{
		match = { { TOK.kwd_let }, { TOK.var_assign }, { TOK.expression, TOK.comparison }, { TOK.op_assign }, { TOK.command, TOK.expression, TOK.string } },
		id = TOK.let_stmt,
		keep = { 2, 5, 3 },
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			if token.children[1].children then
				parse_error(token.children[3].span, 'Expected "=" after group variable assignment, got expression', file)
			end
		end,
	},

	--APPEND variable assignment
	{
		match = { { TOK.kwd_let }, { TOK.var_assign }, { TOK.expr_open }, { TOK.expr_close }, { TOK.op_assign }, { TOK.command, TOK.expression, TOK.string } },
		id = TOK.let_stmt,
		keep = { 2, 6, 3 },
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			if token.children[1].children then
				parse_error(token.children[3].span, 'Expected "=" after group variable assignment, got expression', file)
			end
		end,
	},

	--INVALID variable assignment
	{
		match = { { TOK.kwd_let }, { TOK.var_assign }, { TOK.op_assign } },
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.command },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.children[3].span, 'Missing expression after variable assignment', file)
		end,
	},
	{
		match = { { TOK.kwd_let }, { TOK.var_assign }, { TOK.expression }, { TOK.op_assign } },
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.command },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			parse_error(token.children[3].span, 'Missing expression after variable assignment', file)
		end,
	},

	--Return Statements
	{
		match = { { TOK.kwd_return }, { TOK.command } },
		id = TOK.return_stmt,
		keep = { 2 },
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
		---@param token Token
		---@param file string?
		onmatch = function(token, file)
			--Return value is not really a command, it's a list of values.
			token.children = token.children[1].children
		end,
	},
	{
		match = { { TOK.kwd_return } },
		id = TOK.return_stmt,
		keep = {},
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison, TOK.command },
	},

	--Statements
	{
		match = { { TOK.if_stmt, TOK.while_stmt, TOK.for_stmt, TOK.kv_for_stmt, TOK.let_stmt, TOK.delete_stmt, TOK.subroutine, TOK.gosub_stmt, TOK.return_stmt, TOK.continue_stmt, TOK.kwd_stop, TOK.break_stmt, --[[minify-delete]] TOK.import_stmt, --[[/minify-delete]] TOK.match_stmt, TOK.uncache_stmt, TOK.alias_stmt, TOK.try_stmt } },
		id = TOK.statement,
		meta = true,
	},
	{
		match = { { TOK.statement }, { TOK.line_ending } },
		id = TOK.statement,
		meta = true,
	},

	--Full program
	{
		match = { { TOK.command, TOK.program, TOK.statement }, { TOK.command, TOK.program, TOK.statement } },
		id = TOK.program,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
		not_after = { TOK.op_assign },
		text = 'stmt_list',
	},
	{
		match = { { TOK.program }, { TOK.line_ending } },
		id = TOK.program,
		meta = true,
	},
	{
		match = { { TOK.line_ending }, { TOK.command, TOK.program, TOK.statement, TOK.kwd_for, TOK.kwd_while, TOK.kwd_in, TOK.kwd_do, TOK.kwd_if, TOK.kwd_then, TOK.kwd_elif, TOK.kwd_else, TOK.kwd_end, TOK.kwd_catch, TOK.catch_expr } },
		id = TOK.program,
		onmatch = function(token)
			--Catch possible dead ends where line endings come before any commands.
			for _, i in ipairs({ 'text', 'span', 'id', 'meta_id', 'value', 'filename', 'memoize' }) do
				token[i] = token.children[2][i]
			end
			token.children = token.children[2].children
		end,
	},

	{
		match = { { TOK.line_ending }, { TOK.line_ending } },
		id = TOK.line_ending,
		meta = true,
	},

	--Macro definition
	{
		match = { { TOK.op_exclamation }, { TOK.index_open }, { TOK.comparison }, { TOK.index_close } },
		id = TOK.macro,
		keep = { 3 },
		text = 1,
	},

	--Macro reference
	{
		match = { { TOK.op_exclamation } },
		not_before = { TOK.index_open },
		keep = {},
		text = 1,
		id = TOK.macro_ref,
	},

	--Ternary operator
	{
		match = { { TOK.comparison }, { TOK.kwd_if_expr }, { TOK.comparison }, { TOK.kwd_else_expr }, { TOK.comparison } },
		keep = { 3, 1, 5 },
		text = 'ternary',
		id = TOK.ternary,
		not_after = { TOK.op_dot, TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_div, TOK.op_idiv, TOK.op_mod },
	},

	--Match structure
	{
		match = { { TOK.kwd_match }, { TOK.comparison, TOK.text }, { TOK.kwd_do }, { TOK.program, TOK.command, TOK.statement }, { TOK.kwd_end } },
		keep = { 2, 4, 5 },
		text = 'match',
		id = TOK.match_stmt,
		not_before = { TOK.kwd_else },
		onmatch = _match_stmt_onmatch,
	},
	{
		match = { { TOK.kwd_match }, { TOK.comparison, TOK.text }, { TOK.kwd_do }, { TOK.program, TOK.command, TOK.statement }, { TOK.else_stmt } },
		keep = { 2, 4, 5 },
		text = 'match',
		id = TOK.match_stmt,
		onmatch = _match_stmt_onmatch,
	},
	{
		match = { { TOK.kwd_match }, { TOK.comparison, TOK.text }, { TOK.kwd_do }, { TOK.program, TOK.command, TOK.statement }, { TOK.kwd_else }, { TOK.kwd_end } },
		keep = { 2, 4, 6 },
		text = 'match',
		id = TOK.match_stmt,
		onmatch = _match_stmt_onmatch,
	},
	--Invalid match struct (no comparison branches)
	{
		match = { { TOK.kwd_match }, { TOK.comparison, TOK.text }, { TOK.kwd_do }, { TOK.else_stmt, TOK.kwd_end, TOK.kwd_else } },
		text = 'match',
		id = TOK.match_stmt,
		onmatch = function(token, file)
			parse_error(token.span, 'There must be at least one condition for `match` to compare against', file)
		end,
	},

	--File import statement
	--[[minify-delete]]
	{
		match = { { TOK.kwd_import_file }, { TOK.command } },
		id = TOK.import_stmt,
		keep = { 2 },
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison },
		onmatch = function(token, file)
			local kids = token.children[1].children

			if file == nil then
				file = _G['LSP_FILENAME']
			end

			local current_script_dir = file:match('(.-)([^\\/]-%.?([^%.\\/]*))$')

			token.value = {}
			for i = 1, #kids do
				if kids[i].id ~= TOK.text and (kids[i].id ~= TOK.string_open or not kids[i].children or #kids[i].children > 1 or kids[i].children[1].id ~= TOK.text) then
					parse_error(kids[i].span,
						'All parameters to `' .. token.text .. '` statement must be non-empty string literals', file)
				else
					local orig_filename = kids[i].text
					if kids[i].id == TOK.string_open then orig_filename = kids[i].children[1].text end

					--Make sure import points to a valid file
					local filename = current_script_dir .. orig_filename:gsub('%.', '/') .. '.paisley'
					local fp = io.open(filename, 'r')

					--If the file doesn't exist locally, try the stdlib
					if fp == nil then
						local fname
						fp, fname = _G['STDLIB'](orig_filename)
						if fp then filename = fname end
					end

					if fp == nil then
						parse_error(kids[i].span, 'Cannot load "' .. filename ..
							'": file does not exist or is unreadable', file)
					else
						table.insert(token.value, filename)
					end
				end
			end
			token.children = kids
		end,
	},
	--Invalid import statement
	{
		match = { { TOK.kwd_import_file } },
		id = TOK.import_stmt,
		keep = {},
		text = 1,
		not_before = { TOK.text, TOK.expression, TOK.inline_command, TOK.string, TOK.expr_open, TOK.command_open, TOK.string_open, TOK.comparison, TOK.command },
		onmatch = function(token, file)
			parse_error(token.span, 'At least one file must be given to `' .. token.text .. '` statement', file)
		end,
	},
	--[[/minify-delete]]

	--Subroutine name aliasing statements (using X as Y)
	{
		match = { { TOK.kwd_using }, { TOK.text, TOK.comparison }, { TOK.kwd_as }, { TOK.text, TOK.comparison } },
		id = TOK.alias_stmt,
		keep = { 2, 4 },
		text = 1,
		onmatch = function(token, file)
			for i = 1, #token.children do
				local c = token.children[i]
				if c.id ~= TOK.text then
					parse_error(c.span, 'Expected a subroutine name, got an expression instead', file)
				end
			end
		end,
	},
	--Subroutine alias without an explicit name to assign (using X)
	{
		match = { { TOK.kwd_using }, { TOK.text, TOK.comparison } },
		not_before = { TOK.kwd_as },
		id = TOK.alias_stmt,
		keep = { 2 },
		text = 1,
		onmatch = function(token, file)
			local c = token.children[1]
			local alias = c.text:match('%.[^%.]+$')

			if c.id ~= TOK.text then
				parse_error(c.span, 'Expected a subroutine name, got an expression instead', file)
			elseif not alias then
				parse_error(c.span,
					'Unable to deduce alias from subroutine name (e.g. `A.B` or `A.C.B` will be aliased to `B`)',
					file)
			else
				table.insert(token.children, {
					id = TOK.text,
					span = c.span,
					text = alias:sub(2, #alias),
				})
			end
		end,
	},

	{
		match = { { TOK.kwd_catch }, { TOK.text } },
		id = TOK.catch_expr,
		keep = { 2 },
		text = 1,
		onmatch = function(token, file)
		end,
	},

	{
		match = { { TOK.kwd_try }, { TOK.program, TOK.command, TOK.statement }, { TOK.kwd_catch, TOK.catch_expr }, { TOK.program, TOK.command, TOK.statement }, { TOK.kwd_end } },
		id = TOK.try_stmt,
		keep = { 2, 4, 3 },
		text = 1,
		onmatch = function(token, file)
			local var = token.children[3]
			if var.id == TOK.kwd_catch then
				table.remove(token.children)
			else
				token.children[3] = var.children[1]
			end
		end,
	},
}

--Build a table for quick rule lookup. This is a performance optimization
--Check this lookup table for a rule id instead of looping over every rule every time
local rule_lookup = {}
local _i, _k, _rule, _id
for _i, _rule in pairs(rules) do
	for _k, _id in pairs(_rule.match[1]) do
		if rule_lookup[_id] then
			table.insert(rule_lookup[_id], _i)
		else
			rule_lookup[_id] = { _i }
		end
	end
end

function SyntaxParser(tokens, file)
	if #tokens == 0 then
		return {
			fold = function() return false end,
			get = function() return {} end,
		}
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
	local function reduce(index, expr_indent)
		local this_token = tokens[index]
		local greatest_len = 0
		local unexpected_token = 1

		local possible_rules = rule_lookup[this_token.meta_id]
		if not possible_rules then possible_rules = rule_lookup[this_token.id] end

		if not possible_rules then
			possible_rules = {}
		end

		for _, _r in ipairs(possible_rules) do
			local rule_matches = true
			local rule_failed = false
			local rule = rules[_r]

			if rule.expr_only and expr_indent < 1 then rule_failed = true end

			if (#rule.match + index - 1 <= #tokens) and not rule_failed then
				if rule.not_after and index > 1 then
					local prev_token = tokens[index - 1]
					for i = 1, #rule.not_after do
						if prev_token.id == rule.not_after[i] then
							rule_failed = true
							break
						end
					end
				end

				if not rule_failed and rule.only_after and index > 1 then
					rule_failed = true
					local prev_token = tokens[index - 1]
					for i = 1, #rule.only_after do
						if prev_token.id == rule.only_after[i] then
							rule_failed = false
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
						if not matches(index + rule_index - 1, rule, rule_index) then
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

						for i = 2, #rule.match do
							table.insert(this_token.children, tokens[index + i - 1])
						end

						this_token.span = Span:merge(this_token.span, tokens[index + #rule.match - 1].span)

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

						---@type Token
						local new_token = {
							span = Span:merge(tokens[index].span, tokens[index + #rule.match - 1].span),
							text = text,
							id = rule.id,
							children = {},
							filename = file,
						}

						if rule.keep then
							--We only want to keep certain tokens of the matched group, not all of them.
							for i = 1, #rule.keep do
								table.insert(new_token.children, tokens[index + rule.keep[i] - 1])
							end
						else
							--By default, add all tokens as children.
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
		local expr_indent = 0

		while i <= #tokens do
			local new_token
			local consumed_ct
			local failure_index

			if tokens[i].id == TOK.expr_open then expr_indent = expr_indent + 1 end
			if tokens[i].id == TOK.expr_close then expr_indent = expr_indent - 1 end
			new_token, consumed_ct, failure_index = reduce(i, expr_indent)

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

		if #new_tokens == 2 and new_tokens[2].id == TOK.line_ending then
			table.remove(new_tokens)
		end

		if #new_tokens == 1 then
			--Try one final set of reductions!
			for i = 1, 10 do
				tokens = new_tokens
				new_tokens, did_reduce, first_failure = full_reduce()
				if not did_reduce then break end
			end

			local id = new_tokens[1].id

			if id == TOK.line_ending then
				tokens = {}
				return false
			end

			if (id and id ~= TOK.command and id ~= TOK.kwd_stop and id < TOK.program) or id == TOK.else_stmt or id == TOK.elif_stmt then
				local t = new_tokens[1].text
				if t == '\n' then t = '<newline>' else t = '"' .. t .. '"' end
				parse_error(Span:new(1, 1, 1, 1), 'Unexpected token ' .. t, file)
			end

			tokens = new_tokens
			return false
		end

		loops_since_reduction = loops_since_reduction + 1

		if DEBUG_EXTRA then
			for _, t in pairs(tokens) do
				print_tokens_recursive(t)
			end
			print()
		end

		if not did_reduce or loops_since_reduction > 500 then
			if first_failure == nil then
				parse_error(Span:new(1, 1, 1, 1), 'COMPILER BUG: Max iterations exceeded but no syntax error was found!',
					file)
			end

			local token = tokens[first_failure]
			local t = token.text
			if t == '\n' then t = '<newline>' else t = '"' .. t .. '"' end
			parse_error(token.span, 'Unexpected token ' .. t, file)
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
