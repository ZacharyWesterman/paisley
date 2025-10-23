local parser = require 'src.compiler.ast.parser'

local program
local statement

--Statements
local if_stmt
local else_stmt
local elif_stmt
local while_stmt
local for_stmt
local delete_stmt
local subroutine
local gosub_stmt
local let_stmt
local break_stmt
local continue_stmt
local return_stmt
local match_stmt
local match_if_stmt
local alias_stmt
local try_stmt
local stop_stmt
local import_stmt
local command

--Expressions
local value
local dot
local index
local length
local exponent
local negate
local slice
local mult
local add
local comparison
local concat
local boolean
local list_comprehension
local ternary
local kv_pair
local array

--Misc
local expression
local inline_command
local argument

--Atoms
local macro
local func_call
local string
local parens
local expr
local string_interp

--Helpers for common use cases
local nl = function() parser.skip(TOK.line_ending) end
local exp = function(symbol) return parser.accept(symbol) end
local binary_lassoc = function(lhs_symbol, oper_list, rhs_symbol, node_id)
	local ok, lhs, op, rhs

	ok, lhs = parser.accept(lhs_symbol)
	if not ok then return parser.out(false) end

	ok, op = parser.any_of(oper_list, {})
	if not ok then return true, lhs end

	ok, rhs = parser.expect(rhs_symbol, TOK.expression)
	if not ok then return parser.out(false) end

	return true, {
		id = node_id,
		text = op.text,
		span = Span:merge(lhs.span, rhs.span),
		children = { lhs, rhs },
	}
end

---Syntax rule for array concatenation -> other expressions
array = function(span)
	--A single `,` by itself indicates an empty array.
	local ok, _ = parser.accept(TOK.op_comma)
	if ok then
		return ok, {
			id = TOK.array_concat,
			span = span,
		}
	end

	local lhs, rhs, comma
	ok, lhs = parser.accept(kv_pair)
	if not ok then return parser.out(false) end

	--Not an array_concat expression
	ok, comma = parser.accept(TOK.op_comma)
	if not ok then return true, lhs end

	--Trailing commas are allowed!
	ok, rhs = parser.accept(array)

	return true, {
		id = TOK.array_concat,
		span = Span:merge(span, (ok and rhs or comma).span),
		children = ok and { lhs, rhs } or { lhs },
	}
end

---Syntax rule for key-value pairs -> other expressions
kv_pair = function(span)
	--A single `=>` by itself indicates an empty object.
	local ok, _ = parser.accept(TOK.op_arrow)
	if ok then
		return ok, {
			id = TOK.key_value_pair,
			span = span,
		}
	end

	local lhs, rhs, arrow
	ok, lhs = exp(ternary)
	if not ok then return parser.out(false) end

	--Not an array_concat expression
	ok, arrow = parser.accept(TOK.op_arrow)
	if not ok then return true, lhs end

	--key-value pairs must have values on both sides, and cannot be
	ok, rhs = parser.expect(ternary, 'value for object key')
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.key_value_pair,
		span = Span:merge(span, (ok and rhs or arrow).span),
		children = { lhs, rhs },
	}
end

---Syntax rule for ternary -> other expressions
ternary = function(span)
	local ok, lhs, list

	ok, lhs = exp(list_comprehension)
	if not ok then return parser.out(false) end

	--Just pass on higher-precedence expressions
	ok, _ = parser.accept(TOK.kwd_if_expr)
	if not ok then return true, lhs end

	ok, list = parser.expect_list({
		list_comprehension,
		TOK.kwd_else,
		ternary,
	}, {
		TOK.expression,
		'else',
		TOK.expression,
	})
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.ternary,
		span = Span:merge(span, list[#list].span),
		children = { lhs, list[1], list[3] },
	}
end

---Syntax rule for list comprehension -> other expressions
list_comprehension = function(span)
	local ok, lhs, list

	ok, lhs = exp(boolean)
	if not ok then return parser.out(false) end

	--Just pass on higher-precedence expressions
	ok, _ = parser.accept(TOK.kwd_for_expr)
	if not ok then return true, lhs end

	ok, list = parser.expect_list({
		TOK.variable,
		TOK.op_in,
		list_comprehension,
	}, {
		TOK.variable,
		'in',
		TOK.expression,
	})
	if not ok then return parser.out(false) end

	list = { list[1], list[3] }

	--List filtering condition is optional
	if parser.accept(TOK.kwd_if_expr) then
		local condition
		ok, condition = exp(boolean)

		if not ok then return parser.out(false) end
		table.insert(list, condition)
	end

	return true, {
		id = TOK.list_comp,
		span = Span:merge(span, list[#list].span),
		children = list,
	}
end

---Syntax rule for boolean expressions
boolean = function(span)
	--`not` boolean
	if parser.accept(TOK.op_not) then
		local ok, child = exp(boolean)
		if not ok then return parser.out(false) end
		return true, {
			id = TOK.boolean,
			text = 'not',
			span = Span:merge(span, child.span),
			children = { child },
		}
	end

	local ok, lhs, rhs, op

	--Just pass on higher-precedence expressions
	ok, lhs = exp(concat)
	if not ok then return parser.out(false) end

	--variable `exists`
	ok, op = parser.accept(TOK.op_exists)
	if ok then
		return true, {
			id = TOK.boolean,
			text = 'exists',
			span = Span:merge(span, op.span),
			children = { lhs },
		}
	end

	--binary boolean operations
	ok, op = parser.any_of({
		TOK.op_and,
		TOK.op_or,
		TOK.op_xor,
	}, {})

	if not ok then return true, lhs end

	ok, rhs = exp(boolean)
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.boolean,
		text = op.text,
		span = Span:merge(span, rhs.span),
		children = { lhs, rhs },
	}
end

---Syntax rule for string concatenation
concat = function(span)
	local ok, lhs, rhs

	ok, lhs = exp(comparison)
	if not ok then return parser.out(false) end

	ok, rhs = parser.accept(comparison)
	if not ok then return true, lhs end

	return true, {
		id = TOK.concat,
		span = Span:merge(span, rhs.span),
		children = { lhs, rhs },
	}
end

---Syntax rule for comparison
comparison = function(span)
	local ok, lhs, op, rhs, list

	ok, lhs = exp(add)
	if not ok then return parser.out(false) end

	--Check for special (a `not` `in` b) or (a `not` `like` b) syntax.
	list = parser.peek(2)
	if list[1] == TOK.op_not and (list[2] == TOK.op_in or list[2] == TOK.op_like) then
		parser.nextsym()
		op = parser.t()
		parser.nextsym()

		ok, rhs = exp(comparison)
		if not ok then return parser.out(false) end

		span = Span:merge(span, rhs.span)
		return true, {
			id = TOK.boolean,
			text = 'not',
			span = span,
			children = { {
				id = TOK.boolean,
				text = op.text,
				span = span,
				children = { lhs, rhs },
			} },
		}
	end

	--Just pass on higher-precedence expressions
	ok, op = parser.any_of({
		TOK.op_gt,
		TOK.op_lt,
		TOK.op_ge,
		TOK.op_le,
		TOK.op_eq,
		TOK.op_ne,
		TOK.op_in,
		TOK.op_like,
	}, {})
	if not ok then return true, lhs end

	ok, rhs = exp(comparison)
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.comparison,
		text = op.text,
		span = Span:merge(span, rhs.span),
		children = { lhs, rhs },
	}
end

---Syntax rule for addition
add = function(span)
	return binary_lassoc(
		mult,
		{
			TOK.op_plus,
			TOK.op_minus,
		},
		add,
		TOK.add
	)
end

---Syntax rule for multiplication
mult = function(span)
	return binary_lassoc(
		slice,
		{
			TOK.op_times,
			TOK.op_div,
			TOK.op_idiv,
			TOK.op_mod,
		},
		mult,
		TOK.multiply
	)
end

---Syntax rule for slices
slice = function(span)
	return binary_lassoc(
		negate,
		{ TOK.op_slice },
		slice,
		TOK.array_slice
	)
end

---Syntax rule for negation
negate = function(span)
	if not parser.accept(TOK.op_minus) then return exp(exponent) end

	local ok, child = exp(negate)
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.negate,
		span = Span:merge(span, child.span),
		children = { child },
	}
end

---Syntax rule for exponents
exponent = function(span)
	return binary_lassoc(
		length,
		{ TOK.op_exponent },
		exponent,
		TOK.exponent
	)
end

---Syntax rule for length
length = function(span)
	if not parser.accept(TOK.op_count) then return exp(index) end

	local ok, child = exp(index)
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.length,
		span = Span:merge(span, child.span),
		children = { child },
	}
end

---Syntax rule for array indexing
index = function(span)
	local ok, lhs, rhs, c
	ok, lhs = parser.accept(dot)
	if not ok then return parser.out(false) end

	if not parser.accept(TOK.index_open) then return true, lhs end

	ok, rhs = exp(expression)
	if not ok then return parser.out(false) end

	ok, c = parser.expect(TOK.index_close, ']')
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.index,
		span = Span:merge(span, c.span),
		children = { lhs, rhs },
	}
end

---Syntax rule for dot-notation
dot = function(span)
	--TODO: Dot-notation coerces into either indexing or function calls!

	return binary_lassoc(
		value,
		{ TOK.op_dot },
		dot,
		TOK.op_dot
	)
end

---Syntax rule for bottom-level expression values
value = function(span)
	return parser.any_of({
		macro,
		func_call,
		TOK.variable,
		TOK.lit_number,
		TOK.lit_boolean,
		TOK.lit_null,
		string,
		expr,
		parens,
		inline_command,
	}, {
		TOK.variable,
		TOK.number,
		'true',
		'false',
		'null',
		'(',
		'{',
		'${',
		'!',
	})
end

---Syntax rule for function calls
func_call = function(span)
	local t = parser.peek(2)

	if t[1] ~= TOK.variable or t[2] ~= TOK.paren_open then
		return parser.out(false)
	end

	local ok, list = parser.expect_list({
		TOK.variable,
		TOK.paren_open,
		expression,
		TOK.paren_close,
	}, {
		TOK.variable,
		'(',
		TOK.expression,
		')',
	})
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.func_call,
		text = list[1].text,
		span = Span:merge(span, list[#list].span),
		children = { list[3] },
	}
end

---Syntax rules for macro definitions and uses
macro = function(span)
	local ok, lhs, rhs, c
	ok, lhs = parser.accept(TOK.op_exclamation)
	if not ok then return parser.out(false) end

	if parser.accept(TOK.index_open) then
		ok, rhs = exp(expression)
		if not ok then return parser.out(false) end
		ok, c = parser.expect(TOK.index_close, ']')
		if not ok then return parser.out(false) end

		return true, {
			id = TOK.macro,
			text = lhs.text,
			span = Span:merge(span, c.span),
			children = { rhs },
		}
	end

	lhs.id = TOK.macro_ref
	return true, lhs
end

---Syntax rule for parentheses
parens = function(span)
	if not parser.accept(TOK.paren_open) then return parser.out(false) end
	local ok, child = parser.expect(expression)
	if not ok then return parser.out(false) end
	if not parser.expect(TOK.paren_close) then return parser.out(false) end

	return true, child
end


---Currently, the top-level expression is array syntax
expression = array

---@brief Syntax rule for brace-enclosed expressions
expr = function(span)
	if not parser.accept(TOK.expr_open) then return parser.out(false) end

	local ok, list = parser.expect_list({
		expression,
		TOK.expr_close,
	}, {
		TOK.expression,
		'}',
	})
	if not ok then return parser.out(false) end

	return true, list[1]
end

---@brief Syntax rule for string interpolation values
string_interp = function(span)
	return parser.any_of({
		TOK.text,
		expr,
		inline_command,
	}, {})
end

---@brief Syntax rule for strings
string = function(span)
	local ok, open = parser.accept(TOK.string_open)
	if not ok then return parser.out(false) end

	local list, close
	ok, list = parser.zero_or_more(string_interp)
	ok, close = parser.expect(TOK.string_close, open.text)
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.string_open,
		text = open.text,
		span = Span:merge(span, close.span),
		children = list,
	}
end

---@brief Syntax rule for inline command eval
inline_command = function(span)
	if not parser.accept(TOK.command_open) then return parser.out(false) end

	local ok, child = parser.any_of({
		command,
		gosub_stmt,
	}, {
		TOK.command,
		'gosub',
	}, true)
	if not ok then return parser.out(false) end

	local e
	ok, e = parser.expect(TOK.command_close, '}')
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.inline_command,
		span = Span:merge(span, e.span),
		children = { child },
	}
end

---@brief Syntax rule for command arguments
argument = function()
	return parser.any_of({
		TOK.text,
		string,
		expr,
		inline_command,
	}, {
		TOK.text,
		TOK.string,
		TOK.expression,
		'inline command eval',
	})
end

---@brief Syntax rule for commands
command = function()
	local ok, list = parser.one_or_more(argument)
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.command,
		span = Span:merge(list[1].span, list[#list].span),
		children = list,
	}
end

---@brief Syntax rule for `else` blocks
else_stmt = function(span)
	--Start with `else`
	if not parser.accept(TOK.kwd_else) then return parser.out(false) end

	---`else` program `end`
	local ok, list = parser.expect_list({
		program,
		TOK.kwd_end,
	}, {
		TOK.program,
		'end',
	}, TOK.line_ending)

	return ok, list[1]
end

---@brief Syntax rule for `elif` blocks
elif_stmt = function(span)
	--Start with `elif`
	if not parser.accept(TOK.kwd_elif) then return parser.out(false) end

	--Any missing syntax after this is invalid
	local node = {
		id = TOK.if_stmt,
		text = 'if',
		span = span,
		children = {},
	}

	nl()

	--`elif` argument
	local ok, child = parser.expect(argument, TOK.argument)
	if not ok then return parser.out(false) end
	table.insert(node.children, child)

	nl()

	--`elif` argument `then` ...
	local list
	ok, list = parser.expect_list({
		TOK.kwd_then,
		program,
		{ else_stmt, elif_stmt, TOK.kwd_end },
	}, {
		'then',
		TOK.program,
		{ 'else', 'elif', 'end' }
	}, TOK.line_ending)

	if not ok then return parser.out(false) end

	table.insert(node.children, list[2])
	table.insert(node.children, list[3])

	return ok, node
end

---@brief Syntax rule for `if` blocks
if_stmt = function(span)
	if not parser.accept(TOK.kwd_if) then return parser.out(false) end

	--Any missing syntax after this is invalid
	local node = {
		id = TOK.if_stmt,
		text = 'if',
		span = span,
		children = {},
	}

	nl()

	-- `if` (argument|`gosub`) ...
	local ok, child = parser.any_of({
		argument,
		gosub_stmt,
	}, {
		TOK.argument,
		'gosub',
	}, true)
	if not ok then return parser.out(false) end
	table.insert(node.children, child)

	nl()

	-- `if` argument `then` program ...
	ok, child = parser.accept(TOK.kwd_then)
	if ok then
		ok, child = parser.expect(program, { TOK.program, 'end' })
		if not ok then return parser.out(false) end
		table.insert(node.children, child)

		ok, child = parser.any_of({ else_stmt, elif_stmt, TOK.kwd_end }, { 'else', 'elif', 'end' }, true)
		if not ok then return parser.out(false) end

		if child.id == TOK.kwd_end then
			child = {
				id = TOK.program,
				text = '',
				span = child.span,
				children = {},
			}
		end
		table.insert(node.children, child)

		return ok, node
	end

	-- `if` argument `else`
	ok, child = parser.expect(else_stmt, { 'then', 'else' })
	if not ok then return parser.out(false) end

	table.insert(node.children, {
		id = TOK.program,
		span = span,
		children = {},
	})
	table.insert(node.children, child)

	return ok, node
end

---@brief Syntax rule for `while` blocks
while_stmt = function(span)
	if not parser.accept(TOK.kwd_while) then return parser.out(false) end

	--`while` argument `do` program `end`
	local ok, list = parser.expect_list({
		argument,
		TOK.kwd_do,
		program,
		TOK.kwd_end,
	}, {
		TOK.argument,
		'do',
		{ TOK.program, 'end' },
		'end',
	}, TOK.line_ending)

	if not ok then return parser.out(false) end

	return true, {
		id = TOK.while_stmt,
		span = Span:merge(span, list[#list].span),
		children = { list[1], list[3] },
	}
end

---@brief Syntax rule for `for` block
for_stmt = function(span)
	if not parser.accept(TOK.kwd_for) then return parser.out(false) end

	local node = {
		id = TOK.for_stmt,
		span = span,
		children = {},
	}

	nl()

	--`for` var1 ...
	local ok, child = parser.expect(TOK.text)
	if not ok then return parser.out(false) end
	table.insert(node.children, child)

	--`for` var1 var2 ...
	ok, child = parser.accept(TOK.text)
	if ok then
		node.id = TOK.kv_for_stmt
		table.insert(node.children, child)
	end

	--`for` ... `in` argument+ `do` program `end`
	local list
	ok, list = parser.expect_list({
		TOK.kwd_in,
		function()
			local ok, list = parser.one_or_more(argument)

			if #list > 1 then
				return ok, {
					id = TOK.array_concat,
					span = Span:merge(list[1].span, list[#list].span),
					children = list,
				}
			end

			return ok, list[1]
		end,
		TOK.kwd_do,
		program,
		TOK.kwd_end,
	}, {
		'in',
		'argument(s)',
		'do',
		{ TOK.program, 'end' },
		'end',
	}, TOK.line_ending)
	if not ok then return parser.out(false) end

	table.insert(node.children, list[2])
	table.insert(node.children, list[4])
	node.span = Span:merge(span, list[#list].span)

	return true, node
end

---@brief Syntax rule for `subroutine` block
subroutine = function(span)
	local memoize = false

	if parser.accept(TOK.kwd_cache) then
		memoize = true
		if not parser.expect(TOK.kwd_subroutine, 'subroutine') then
			return parser.out(false)
		end
	else
		if not parser.accept(TOK.kwd_subroutine) then
			return parser.out(false)
		end
	end

	local ok, list = parser.expect_list({
		TOK.text,
		program,
		TOK.kwd_end,
	}, {
		'subroutine name',
		TOK.program,
		'end',
	})
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.subroutine,
		text = list[1].text,
		span = Span:merge(span, list[3].span),
		children = { list[2] },
		memoize = memoize,
	}
end

---@brief Syntax rule for `gosub` statement
gosub_stmt = function(span)
	if not parser.accept(TOK.kwd_gosub) then return parser.out(false) end

	local _, list
	local ok, list = parser.one_or_more(argument)
	if not ok then
		parser.ast_error(parser.t(), { TOK.argument })
		return parser.out(false)
	end

	return true, {
		id = TOK.gosub_stmt,
		text = 'gosub',
		span = Span:merge(span, list[#list].span),
		children = list,
	}
end

---@brief Syntax rule for `let` statement
let_stmt = function(span)
	local ok, child = parser.any_of({ TOK.kwd_let, TOK.kwd_initial }, {})
	if not ok then return parser.out(false) end

	local is_initial = child.id == TOK.kwd_initial

	local list
	ok, list = parser.one_or_more(TOK.var_assign)
	if not ok then
		parser.ast_error(parser.t(), 'variable name')
		return parser.out(false)
	end

	local node = {
		id = TOK.let_stmt,
		text = is_initial and 'initial' or 'let',
		span = Span:merge(span, list[#list].span),
		children = { list[1] },
	}

	if #list > 1 then
		if is_initial then
			--Multi-assignment is not allowed with `initial` statement
			parse_error(list[2].span, 'Only a single variable may be initialized at a time.', parser.filename())
			return parser.out(false)
		end

		--In multi-assignment, append child vars to first one.
		list[1].children = {}
		for i = 2, #list do
			table.insert(list[1].children, list[i])
		end
	else
		--Indexed assignment is only available in single assignment
		ok, child = parser.accept(TOK.expr_open)
		if ok then
			if is_initial then
				--Indexed assignment is not allowed with `initial` statement
				parser.ast_error(child, '=')
				return parser.out(false)
			end

			if not parser.accept(TOK.expr_close) then
				ok, child = parser.expect(expression, 'expression')
				if not ok or not parser.expect(TOK.expr_close, '}') then
					return parser.out(false)
				end
			end

			--Indexed assignment MUST have an `=` operator after it.
			if not parser.expect(TOK.op_assign, '=') then
				return parser.out(false)
			end

			--and then at least one value
			local ch2
			ok, ch2 = parser.expect(command, 'argument(s)')
			if not ok then return parser.out(false) end

			table.insert(node.children, ch2)
			table.insert(node.children, child)

			return true, node
		end
	end

	--There are two valid assignment syntaxes.
	--The first assigns vars to a specific value,
	--and the second just defines them and assigns null.
	--`let` ... `=` ...
	--`let` ...
	ok, child = parser.accept(TOK.op_assign)
	if not ok then
		if is_initial then
			--A value must be given in `initial` statement
			parser.ast_error(child, '=')
			return parser.out(false)
		end
		return true, node
	end

	ok, child = parser.expect(command, 'argument(s)')
	if not ok then return parser.out(false) end
	table.insert(node.children, child)

	return true, node
end

---@brief Syntax rule for `break` statement and `break cache` statement
break_stmt = function(span)
	if not parser.accept(TOK.kwd_break) then return parser.out(false) end

	local id = TOK.break_stmt

	--`break` `cache` argument
	--is different from the regular `break` statement, but has very similar syntax
	if parser.accept(TOK.kwd_cache) then
		id = TOK.uncache_stmt
	end

	local ok, child = parser.zero_or_one(argument, TOK.argument)

	return true, {
		id = id,
		span = ok and Span:merge(span, child.span) or span,
		children = ok and { child } or {},
	}
end

---@brief Syntax rule for `continue` statement
continue_stmt = function(span)
	if not parser.accept(TOK.kwd_continue) then return parser.out(false) end

	local ok, child = parser.zero_or_one(argument, TOK.argument)

	return true, {
		id = TOK.continue_stmt,
		span = ok and Span:merge(span, child.span) or span,
		children = ok and { child } or {},
	}
end

---@brief Syntax rule for `return` statement
return_stmt = function(span)
	if not parser.accept(TOK.kwd_return) then return parser.out(false) end

	local ok, child = parser.zero_or_one(argument, TOK.argument)

	return true, {
		id = TOK.return_stmt,
		span = ok and Span:merge(span, child.span) or span,
		children = ok and { child } or {},
	}
end

---@brief Syntax rule for `match` block
match_stmt = function(span)
	if not parser.accept(TOK.kwd_match) then return parser.out(false) end

	--`match` argument `do` (match_if_stmt)+ (`else`... `end`|`end`)
	local ok, list = parser.expect_list({
		argument,
		TOK.kwd_do,
		function()
			local ok, list = parser.one_or_more(match_if_stmt)
			if not ok then return parser.out(false) end

			return ok, {
				id = TOK.program,
				span = Span:merge(list[1].span, list[#list].span),
				children = list,
			}
		end,
		{ else_stmt, TOK.kwd_end },
	}, {
		TOK.argument,
		'do',
		'if',
		{ 'else', 'end' },
	}, TOK.line_ending)
	if not ok then return parser.out(false) end

	local node = {
		id = TOK.match_stmt,
		span = span,
		children = {
			list[1],
			list[3],
			list[4].id == TOK.else_stmt and list[4] or {
				id = TOK.program,
				span = list[4].span,
			},
		}
	}

	return true, node
end

---@brief Syntax rule for the simpler `if` blocks that are allowed inside `match` blocks.
match_if_stmt = function(span)
	nl()
	if not parser.accept(TOK.kwd_if) then return parser.out(false) end

	local ok, list = parser.expect_list({
		argument,
		TOK.kwd_then,
		program,
		TOK.kwd_end,
	}, {
		TOK.argument,
		'then',
		{ TOK.program, 'end' },
		'end',
	}, TOK.line_ending)
	if not ok then return parser.out(false) end

	return true, {
		id = TOK.if_stmt,
		span = Span:merge(span, list[#list].span),
		children = { list[1], list[3] },
	}
end

---@brief Syntax rule for `using` statement
alias_stmt = function(span)
	if not parser.accept(TOK.kwd_using) then return parser.out(false) end

	local node = {
		id = TOK.alias_stmt,
		span = span,
		children = {},
	}

	local ok, child = parser.expect(TOK.text)
	if not ok then return parser.out(false) end
	table.insert(node.children, child)

	if parser.accept(TOK.kwd_as) then
		ok, child = parser.expect(TOK.text)
		if not ok then return parser.out(false) end
		table.insert(node.children, child)
	else
		--Deduce alias conversion here
		local alias = child.text:match('%.[^%.]+$')

		if not alias then
			parse_error(
				child.span,
				'Unable to deduce alias from subroutine name "' ..
				child.text .. '" (e.g. `A.B` or `A.C.B` will be aliased to `B`)',
				parser.filename()
			)
			return false, node
		end

		table.insert(node.children, {
			id = TOK.text,
			span = child.span,
			text = alias:sub(2, #alias),
		})
	end

	return true, node
end

---@brief Syntax rule for `try`/`catch` blocks
try_stmt = function(span)
	if not parser.accept(TOK.kwd_try) then return parser.out(false) end

	local ok, list
	local has_var = true

	--`try` program `catch` text? program `end`
	ok, list = parser.expect_list({
		program,
		TOK.kwd_catch,
		function()
			local ok, child = parser.accept(TOK.text)
			if not ok then has_var = false end
			return true, child
		end,
		program,
		TOK.kwd_end,
	}, {
		TOK.program,
		'catch',
		'variable name',
		TOK.program,
		'end',
	}, TOK.line_ending)
	if not ok then return parser.out(false) end

	local node = {
		id = TOK.try_stmt,
		span = Span:merge(span, list[#list].span),
		children = {
			list[1],
			list[4],
		},
	}
	--Note that the variable always goes last since it's optional
	if has_var then table.insert(node.children, list[3]) end

	return true, node
end

---@brief Syntax rule for `delete` statement
delete_stmt = function(span)
	if not parser.accept(TOK.kwd_delete) then return parser.out(false) end

	---`delete` var1 var2 ... etc
	local ok, list = parser.one_or_more(argument)
	if not ok then
		parser.ast_error(parser.t(), TOK.argument)
		return parser.out(false)
	end

	return ok, {
		id = TOK.delete_stmt,
		span = Span:merge(span, list[#list].span),
		text = 'delete',
		children = list,
	}
end

---@brief Syntax rule for `stop` statement
stop_stmt = function(span)
	return parser.accept(TOK.kwd_stop)
end

--[[minify-delete]]
---@brief Syntax rule for `require` statements
import_stmt = function(span)
	if not parser.accept(TOK.kwd_import_file) then return parser.out(false) end

	local ok, list = parser.one_or_more(TOK.text)
	if not ok then
		parse_error(span, 'One or more module names expected after `require`.', parser.filename())
		return parser.out(false)
	end

	local files = {}

	local file = parser.filename() or _G['LSP_FILENAME'] or ''
	local current_script_dir = file:match('(.-)([^\\/]-%.?([^%.\\/]*))$')

	local function pai(filename)
		local fname = filename:gsub('%.', '/')
		local fp = io.open(fname .. '.pai')
		if fp then
			return fp, fname .. '.pai'
		end
		return io.open(fname), fname .. '.paisley'
	end

	--For each file in the list,
	for i = 1, #list do
		local orig_filename = list[i].text

		--Make sure import points to a valid file
		local fp, filename = pai(current_script_dir .. orig_filename)

		--If the file doesn't exist locally, try the stdlib
		if fp == nil then
			local fname
			---@diagnostic disable-next-line
			fp, fname = _G['FS'].stdlib(orig_filename)
			if fp then filename = fname end
		end

		if fp == nil then
			parse_error(list[i].span, 'Cannot load "' .. filename ..
				'": file does not exist or is unreadable', file)
		else
			table.insert(files, filename)
			fp:close()
		end
	end

	return true, {
		id = TOK.import_stmt,
		span = Span:merge(span, list[#list].span),
		value = files,
	}
end
--[[/minify-delete]]

statement = function()
	return parser.any_of({
		TOK.line_ending,
		if_stmt,
		while_stmt,
		for_stmt,
		subroutine,
		gosub_stmt,
		let_stmt,
		delete_stmt,
		break_stmt,
		continue_stmt,
		return_stmt,
		match_stmt,
		alias_stmt,
		try_stmt,
		stop_stmt,
		--[[minify-delete]] import_stmt, --[[/minify-delete]]
		command,
	}, {}, false)
end

---@brief Syntax rule for a list of statements
program = function()
	local span = parser.t().span
	local ok, statements = parser.zero_or_more(statement)

	local pgm = {
		id = TOK.program,
		span = span,
		children = {},
	}

	--Remove newlines from program
	for _, s in ipairs(statements) do
		if s.id ~= TOK.line_ending then
			table.insert(pgm.children, s)
		end
	end

	if #statements > 0 then
		pgm.span = Span:merge(
			statements[1].span,
			statements[#statements].span
		)
	end

	return ok, pgm
end


---@brief Parse the list of tokens into an AST.
return function()
	parser.nextsym()
	local ok, node = program()

	if parser.t() then
		parser.ast_error(parser.t())
	end

	return node
end
