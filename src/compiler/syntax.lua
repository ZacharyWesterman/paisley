local rules = {
	--Function call, dot-notation
	{
		match = {{tok.value, tok.func_call}, {tok.op_dot}, {tok.value, tok.func_call, tok.comparison}},
		id = tok.func_call,
		text = 3,
		not_after = {tok.op_dot},
		onmatch = function(token, file)
			if token.children[3].id ~= tok.func_call then
				parse_error(token.line, token.col, 'Dot notation can only be used with function calls', file)
			end

			table.insert(token.children[3].children, 1, token.children[1])
			token.children = token.children[3].children
		end,
	},

	--String Concatenation
	{
		match = {{tok.comparison, tok.array_concat}, {tok.comparison, tok.array_concat}},
		id = tok.concat,
		not_after = {tok.op_assign, tok.string_close, tok.text},
		not_before = {tok.index_open},
		expr_only = true,
		text = '..',
	},

	--Empty expressions (ERROR)
	{
		match = {{tok.expr_open}, {tok.expr_close}},
		not_after = {tok.var_assign},
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Expression has no body', file)
		end,
	},
	--Empty command (ERROR)
	{
		match = {{tok.command_open}, {tok.command_close}},
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Inline command evaluation has no body', file)
		end,
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

	--Special "reduce" function call
	{
		match = {{tok.text, tok.variable}, {tok.paren_open}, {tok.comparison}, {tok.op_comma}, {tok.op_plus, tok.op_minus, tok.op_times, tok.op_idiv, tok.op_div, tok.op_mod, tok.op_and, tok.op_or, tok.op_xor, tok.op_ge, tok.op_gt, tok.op_le, tok.op_lt, tok.op_eq, tok.op_ne}, {tok.paren_close}},
		id = tok.func_call,
		keep = {3, 5},
		text = 1,
	},
	--Special "reduce", function call (for dot notation)
	{
		match = {{tok.text, tok.variable}, {tok.paren_open}, {tok.op_plus, tok.op_minus, tok.op_times, tok.op_idiv, tok.op_div, tok.op_mod, tok.op_and, tok.op_or, tok.op_xor, tok.op_ge, tok.op_gt, tok.op_le, tok.op_lt, tok.op_eq, tok.op_ne}, {tok.paren_close}},
		id = tok.func_call,
		keep = {3},
		text = 1,
	},

	--Array indexing
	{
		match = {{tok.comparison}, {tok.index_open}, {tok.comparison}, {tok.index_close}},
		id = tok.index,
		keep = {1, 3},
		text = 2,
		not_after = {tok.op_dot},
	},

	--Treat all literals the same.
	{
		match = {{tok.lit_number, tok.lit_boolean, tok.lit_null, tok.negate, tok.string, tok.parentheses, tok.func_call, tok.index, tok.expression, tok.inline_command, tok.concat, tok.lambda, tok.lambda_ref, tok.ternary, tok.list_comp, tok.key_value_pair}},
		id = tok.value,
		meta = true,
	},
	{
		match = {{tok.variable}},
		id = tok.value,
		meta = true,
		not_before = {tok.paren_open},
		not_after = {tok.kwd_for_expr},
	},

	--Length operator
	{
		match = {{tok.op_count}, {tok.value, tok.comparison}},
		id = tok.length,
		keep = {2},
		text = 1,
		not_before = {tok.paren_open, tok.op_dot},
	},

	--Unary negation is a bit weird; highest precedence and cannot occur after certain nodes.
	{
		match = {{tok.op_minus}, {tok.value, tok.comparison}},
		id = tok.negate,
		keep = {2},
		text = 1,
		not_after = {tok.lit_number, tok.lit_false, tok.lit_true, tok.lit_null, tok.negate, tok.command_close, tok.expr_close, tok.string_close, tok.string_open, tok.paren_close, tok.inline_command, tok.expression, tok.parentheses, tok.variable, tok.func_call},
		not_before = {tok.op_dot},
	},

	--Exponentiation
	{
		match = {{tok.value, tok.exponent, tok.comparison}, {tok.op_exponent}, {tok.value}},
		id = tok.exponent,
		not_after = {tok.op_exponent, tok.op_dot},
		keep = {1, 3},
		text = 2,
		not_before = {tok.op_dot},
	},

	--If no other exponent was detected, just promote the value.
	--This is to keep exponent as higher precedence than multiplication.
	{
		match = {{tok.value}},
		id = tok.multiply,
		meta = true,
		not_before = {tok.op_dot},
	},

	--Multiplication
	{
		match = {{tok.value, tok.multiply, tok.comparison}, {tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod}, {tok.value, tok.multiply, tok.comparison}},
		id = tok.multiply,
		not_after = {tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod, tok.op_dot},
		keep = {1, 3},
		text = 2,
		not_before = {tok.op_dot},
	},

	--If no other multiplication was detected, just promote the value to mult status.
	--This is to keep mult as higher precedence than addition.
	{
		match = {{tok.value}},
		id = tok.multiply,
		meta = true,
		not_before = {tok.op_dot},
	},

	--Addition (lower precedence than multiplication)
	{
		match = {{tok.exponent, tok.multiply, tok.add, tok.comparison}, {tok.op_plus, tok.op_minus}, {tok.exponent, tok.multiply, tok.add, tok.comparison}},
		id = tok.add,
		not_before = {tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod},
		not_after = {tok.op_plus, tok.op_minus, tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod, tok.op_dot},
		keep = {1, 3},
		text = 2,
	},

	--If no other addition was detected, just promote the value to add status.
	--This is to keep add as higher precedence than boolean.
	{
		match = {{tok.exponent, tok.multiply}},
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
	{ --non-terminated array slicing
		match = {{tok.add, tok.array_slice, tok.comparison}, {tok.op_slice}, {tok.op_slice}},
		id = tok.array_slice,
		keep = {1},
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
		not_before = {tok.index_open, tok.op_arrow},
		not_after = {tok.op_dot, tok.op_arrow},
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
		not_before = {tok.lit_boolean, tok.lit_null, tok.lit_number, tok.string_open, tok.command_open, tok.expr_open, tok.array_slice, tok.array_concat, tok.comparison, tok.paren_open, tok.index_open, tok.parentheses, tok.variable, tok.func_call, tok.index, tok.op_plus, tok.op_minus, tok.op_times, tok.op_idiv, tok.op_div, tok.op_mod, tok.op_and, tok.op_or, tok.op_xor, tok.op_ge, tok.op_gt, tok.op_le, tok.op_lt, tok.op_eq, tok.op_ne, tok.op_arrow, tok.key_value_pair},
		not_after = {tok.op_arrow},
	},
	{
		match = {{tok.op_comma}},
		id = tok.array_concat,
		keep = {},
		text = 1,
		only_after = {tok.expr_open, tok.paren_open},
	},

	--Object definitions, key-value pairs
	{
		match = {{tok.comparison}, {tok.op_arrow}, {tok.comparison}},
		id = tok.key_value_pair,
		keep = {1, 3},
		text = 2,
		not_before = {tok.lit_boolean, tok.lit_null, tok.lit_number, tok.string_open, tok.command_open, tok.expr_open, tok.array_slice, tok.array_concat, tok.comparison, tok.paren_open, tok.index_open, tok.parentheses, tok.variable, tok.func_call, tok.index, tok.op_plus, tok.op_minus, tok.op_times, tok.op_idiv, tok.op_div, tok.op_mod, tok.op_and, tok.op_or, tok.op_xor, tok.op_ge, tok.op_gt, tok.op_le, tok.op_lt, tok.op_eq, tok.op_ne},
	},
	{
		match = {{tok.op_arrow}},
		id = tok.key_value_pair,
		keep = {},
		text = 1,
		only_after = {tok.op_comma, tok.expr_open, tok.paren_open},
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
		not_after = {tok.op_dot, tok.op_plus, tok.op_minus, tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod},
	},
	{
		match = {{tok.array_concat, tok.boolean, tok.comparison}, {tok.op_in}, {tok.array_concat, tok.boolean, tok.comparison}},
		id = tok.boolean,
		keep = {1, 3},
		text = 2,
		not_after = {tok.kwd_for_expr, tok.op_dot},
		not_before = {tok.op_dot, tok.op_plus, tok.op_minus, tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod},
	},

	--Special "{value not in array}" syntax
	{
		match = {{tok.array_concat, tok.boolean, tok.comparison}, {tok.op_not}, {tok.op_in}, {tok.array_concat, tok.boolean, tok.comparison}},
		id = tok.boolean,
		keep = {1, 4},
		text = 3,
		not_after = {tok.op_dot, tok.op_plus, tok.op_minus, tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod},
		onmatch = function(token, file)
			return {
				text = 'not',
				id = tok.boolean,
				line = token.line,
				col = token.col,
				children = {token},
			}
		end,
	},

	--List comprehension
	{
		match = {{tok.comparison}, {tok.kwd_for_expr}, {tok.variable}, {tok.op_in}, {tok.comparison}},
		id = tok.list_comp,
		keep = {1, 3, 5},
		text = 2,
		not_before = {tok.kwd_if_expr, tok.op_dot},
	},
	{
		match = {{tok.comparison}, {tok.kwd_for_expr}, {tok.variable}, {tok.op_in}, {tok.comparison}, {tok.kwd_if_expr}, {tok.comparison}},
		id = tok.list_comp,
		keep = {1, 3, 5, 7},
		text = 2,
		not_before = {tok.kwd_else_expr, tok.op_dot},
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
			if token.text == '=' then token.text = '==' end
		end,
		not_after = {tok.op_dot, tok.op_plus, tok.op_minus, tok.op_times, tok.op_div, tok.op_idiv, tok.op_mod},
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
		not_after = {tok.kwd_for, tok.kwd_subroutine, tok.kwd_if_expr, tok.kwd_else_expr, tok.var_assign},
		text = 'cmd',
	},
	{
		match = {{tok.command}, {tok.text, tok.expression, tok.inline_command, tok.string, tok.comparison}},
		append = true,
	},

	--IF block
	{
		match = {{tok.kwd_if}, {tok.command, tok.gosub_stmt}, {tok.kwd_then}, {tok.command, tok.program, tok.statement}, {tok.kwd_end, tok.elif_stmt, tok.else_stmt}},
		id = tok.if_stmt,
		keep = {2, 4, 5},
		text = 1,
	},
	{
		match = {{tok.kwd_if}, {tok.command, tok.gosub_stmt}, {tok.kwd_then}, {tok.kwd_end, tok.elif_stmt, tok.else_stmt}},
		id = tok.if_stmt,
		keep = {2, 3, 4},
		text = 1,
	},
	{
		match = {{tok.kwd_if}, {tok.command, tok.gosub_stmt}, {tok.else_stmt}},
		id = tok.if_stmt,
		keep = {2, 1, 3},
		text = 1,
		onmatch = function(token, file)
			token.children[2].id = tok.kwd_then
		end,
	},
	{ --Invalid if
		match = {{tok.kwd_if}, {tok.command, tok.gosub_stmt}},
		id = tok.if_stmt,
		text = 1,
		not_before = {tok.kwd_then, tok.line_ending, tok.kwd_else, tok.else_stmt},
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Missing "then" or "else" after if statement', file)
		end,
	},
	--ELSE block
	{
		match = {{tok.kwd_else}, {tok.command, tok.program, tok.statement}, {tok.kwd_end}},
		id = tok.else_stmt,
		keep = {2},
		text = 1,
	},
	{ --Empty else block
		match = {{tok.kwd_else}, {tok.kwd_end}},
		id = tok.else_stmt,
		keep = {},
		text = 1,
	},
	--ELIF block
	{
		match = {{tok.kwd_elif}, {tok.command}, {tok.kwd_then}, {tok.command, tok.program, tok.statement}, {tok.kwd_end, tok.elif_stmt, tok.else_stmt}},
		id = tok.elif_stmt,
		keep = {2, 4, 5},
		text = 1,
	},
	{
		match = {{tok.kwd_elif}, {tok.command}, {tok.kwd_then}, {tok.kwd_end, tok.elif_stmt, tok.else_stmt}},
		id = tok.elif_stmt,
		keep = {2, 3, 4},
		text = 1,
	},
	{ --Invalid elif
		match = {{tok.kwd_elif}, {tok.command}},
		id = tok.if_stmt,
		text = 1,
		not_before = {tok.kwd_then, tok.line_ending},
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Missing "then" after elif statement', file)
		end,
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
		match = {{tok.kwd_subroutine}, {tok.text}, {tok.command, tok.program, tok.statement}, {tok.kwd_end}},
		id = tok.subroutine,
		keep = {3},
		text = 2,
	},
	{
		match = {{tok.kwd_subroutine}, {tok.text}, {tok.kwd_end}},
		id = tok.subroutine,
		keep = {},
		text = 2,
	},
	{
		match = {{tok.kwd_subroutine}, {tok.text}, {tok.line_ending}, {tok.kwd_end}},
		id = tok.subroutine,
		keep = {},
		text = 2,
	},

	--Invalid subroutine
	{
		match = {{tok.kwd_subroutine}},
		id = tok.subroutine,
		not_before = {tok.text},
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
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison, tok.op_assign, tok.var_assign},
	},
	--Assign multiple variables at the same time
	{
		match = {{tok.var_assign}, {tok.var_assign}},
		id = tok.var_assign,
		text = 1,
		keep = {1, 2},
		not_after = {tok.var_assign},
		onmatch = function(token, file)
			local t = token.children[1]
			if t.children == nil then t.children = {} end
			table.insert(t.children, token.children[2])
			return token.children[1]
		end,
	},

	--Variable initialization
	{
		match = {{tok.kwd_initial}, {tok.var_assign}, {tok.op_assign}, {tok.command, tok.expression, tok.string}},
		id = tok.let_stmt,
		keep = {2, 4},
		text = 1,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison},
	},
	{
		match = {{tok.kwd_initial}, {tok.var_assign}},
		id = tok.let_stmt,
		keep = {2},
		text = 1,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison, tok.op_assign},
		onmatch = function(token, file)
			parse_error(token.line, token.col, 'Incomplete variable initialization, `'.. token.children[1].text ..'` must have a value', file)
		end,
	},

	--SUB variable assignment
	{
		match = {{tok.kwd_let}, {tok.var_assign}, {tok.expression}, {tok.op_assign}, {tok.command, tok.expression, tok.string}},
		id = tok.let_stmt,
		keep = {2, 5, 3},
		text = 1,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison},
		onmatch = function(token, file)
			if token.children[1].children then
				parse_error(token.children[3].line, token.children[3].col, 'Expected "=" after group variable assignment, got expression', file)
			end
		end,
	},

	--APPEND variable assignment
	{
		match = {{tok.kwd_let}, {tok.var_assign}, {tok.expr_open}, {tok.expr_close}, {tok.op_assign}, {tok.command, tok.expression, tok.string}},
		id = tok.let_stmt,
		keep = {2, 6, 3},
		text = 1,
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.comparison},
		onmatch = function(token, file)
			if token.children[1].children then
				parse_error(token.children[3].line, token.children[3].col, 'Expected "=" after group variable assignment, got expression', file)
			end
		end,
	},

	--INVALID variable assignment
	{
		match = {{tok.kwd_let}, {tok.var_assign}, {tok.op_assign}},
		not_before = {tok.text, tok.expression, tok.inline_command, tok.string, tok.expr_open, tok.command_open, tok.string_open, tok.command},
		onmatch = function(token, file)
			parse_error(token.children[3].line, token.children[3].col, 'Missing expression after variable assignment', file)
		end,
	},
	{
		match = {{tok.kwd_let}, {tok.var_assign}, {tok.expression}, {tok.op_assign}},
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
		not_after = {tok.op_assign},
		text = 'stmt_list',
	},
	{
		match = {{tok.program}, {tok.line_ending}},
		id = tok.program,
		meta = true,
	},
	{
		match = {{tok.line_ending}, {tok.command, tok.program, tok.statement, tok.kwd_for, tok.kwd_while, tok.kwd_in, tok.kwd_do, tok.kwd_if, tok.kwd_then, tok.kwd_elif, tok.kwd_else, tok.kwd_end}},
		id = tok.program,
		onmatch = function(token)
			--Catch possible dead ends where line endings come before any commands.
			local i, _
			for _, i in ipairs({'text', 'line', 'col', 'id', 'meta_id', 'value'}) do
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

	--Lambda definition
	{
		match = {{tok.op_exclamation}, {tok.index_open}, {tok.comparison}, {tok.index_close}},
		id = tok.lambda,
		keep = {3},
		text = 1,
	},

	--Lambda reference
	{
		match = {{tok.op_exclamation}},
		not_before = {tok.index_open},
		keep = {},
		text = 1,
		id = tok.lambda_ref,
	},

	--Ternary operator
	{
		match = {{tok.comparison}, {tok.kwd_if_expr}, {tok.comparison}, {tok.kwd_else_expr}, {tok.comparison}},
		keep = {3, 1, 5},
		text = 'ternary',
		id = tok.ternary,
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
			rule_lookup[_id] = {_i}
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
		local _, rule
		local this_token = tokens[index]
		local greatest_len = 0
		local unexpected_token = 1

		local possible_rules = rule_lookup[this_token.meta_id]
		if not possible_rules then possible_rules = rule_lookup[this_token.id] end

		if not possible_rules then
			-- unexpected_token = index
			possible_rules = {}
			-- parse_error(this_token.line, this_token.col, 'COMPILER BUG: No AST rule for token "'..token_text(this_token.id)..'"', file)
		end

		for _, _r in ipairs(possible_rules) do
			local rule_index
			local rule_matches = true
			local rule_failed = false
			local rule = rules[_r]

			if rule.expr_only and expr_indent < 1 then rule_failed = true end

			if (#rule.match + index - 1 <= #tokens) and not rule_failed then
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

				if not rule_failed and rule.only_after and index > 1 then
					rule_failed = true
					local prev_token, i = tokens[index - 1]
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
		local expr_indent = 0

		while i <= #tokens do
			local new_token
			local consumed_ct
			local failure_index

			if tokens[i].id == tok.expr_open then expr_indent = expr_indent + 1 end
			if tokens[i].id == tok.expr_close then expr_indent = expr_indent - 1 end
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

		if #new_tokens == 2 and new_tokens[2].id == tok.line_ending then
			table.remove(new_tokens)
		end

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
				tokens = {}
				return false
			end

			if (id ~= tok.command and id ~= tok.kwd_stop and id < tok.program) or id == tok.else_stmt or id == tok.elif_stmt then
				parse_error(1, 1, 'Unexpected token "'..new_tokens[1].text..'"', file)
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
