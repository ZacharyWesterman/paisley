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
local uncache_stmt
local break_stmt
local continue_stmt
local match_stmt
local alias_stmt
local try_stmt
local stop_stmt
local command

--Expressions
local value
local dot
local index
local length
local exponent
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
local variable
local number
local string
local literal
local parens
local string_interpolation

---@brief Syntax rule for command arguments
argument = function()
	return parser.any_of({
		TOK.text,
		string,
		expression,
		inline_command,
	}, {
		TOK.text,
		TOK.string,
		TOK.expression,
		TOK.inline_command,
	})
end

---@brief Syntax rule for commands
command = function()
	local ok, arguments = parser.one_or_more(argument)
	if not ok then return parser.out(false) end

	local cmd = {
		id = TOK.command,
		text = 'command',
		span = {
			from = arguments[1].span.from,
			to = arguments[#arguments].span.to,
		},
		children = arguments,
	}

	return true, cmd
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

	-- `if` argument ...
	local ok, child = parser.expect(argument)
	if not ok then return parser.out(false) end

	-- `if` argument `then` ...
	ok, child = parser.accept(TOK.kwd_then)
	if ok then
		---
		return ok, node
	end

	-- `if` argument `else`
	ok, child = parser.expect(else_stmt, 'else')


	local ok, list = parser.expect_list({
		argument,
		{ TOK.kwd_then },
		program,
		{ TOK.kwd_end, else_stmt },
	}, {
		{ TOK.text, 'string' },
		{ 'then' },
		'program',
		{ 'end', 'else' },
	}, TOK.line_ending)

	node.children = list

	return ok, node
end

statement = function()
	return parser.any_of({
		TOK.line_ending,
		command,
		if_stmt,
	}, {
		TOK.line_ending,
		TOK.command,
		'if',
	}, false)
end

program = function()
	local span = parser.t().span
	local ok, statements = parser.zero_or_more(statement)

	local pgm = {
		id = TOK.program,
		text = 'program',
		span = span,
		children = statements,
	}

	if #statements > 0 then
		pgm.span = Span:merge(
			statements[1].span,
			statements[#statements].span
		)
	end

	return ok, pgm
end

--

return function()
	parser.nextsym()
	local ok, node = program()
	return node
end
