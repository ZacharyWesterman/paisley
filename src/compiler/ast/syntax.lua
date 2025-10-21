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

--Helpers for common use cases
local nl = function() parser.skip(TOK.line_ending) end

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
		text = '',
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
	local ok, child = parser.expect(argument)
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

	-- `if` argument ...
	local ok, child = parser.expect(argument)
	if not ok then return parser.out(false) end

	nl()

	-- `if` argument `then` program ...
	ok, child = parser.accept(TOK.kwd_then)
	if ok then
		table.insert(node.children, child)

		ok, child = parser.expect(program)
		if not ok then return parser.out(false) end

		ok, child = parser.any_of({ else_stmt, elif_stmt, TOK.kwd_end }, { 'else', 'elif', 'end' }, true)
		if not ok then return parser.out(false) end
		table.insert(node.children, child)

		return ok, node
	end

	-- `if` argument `else`
	ok, child = parser.expect(else_stmt, 'else')
	if not ok then return parser.out(false) end

	node.children = {
		{
			id = TOK.kwd_then,
			text = 'then',
			span = span,
		},
		child,
	}

	return ok, node
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

	local ok, list = parser.one_or_more(argument)

	return true, {
		id = TOK.gosub_stmt,
		text = 'gosub',
		span = ok and Span:merge(span, list[#list].span) or span,
		children = ok and list or {},
	}
end

---@brief Syntax rule for `break` statement and `break cache` statement
break_stmt = function(span)
	if not parser.accept(TOK.kwd_break) then return parser.out(false) end

	local id = TOK.break_stmt
	local text = 'break'

	--`break` `cache` argument
	--is different from the regular `break` statement, but has very similar syntax
	if parser.accept(TOK.kwd_cache) then
		id = TOK.uncache_stmt
		text = 'break cache'
	end

	local ok, list = parser.one_or_more(argument)

	return true, {
		id = id,
		text = text,
		span = ok and Span:merge(span, list[#list].span) or span,
		children = ok and list or {},
	}
end

---@brief Syntax rule for `continue` statement
continue_stmt = function(span)
	if not parser.accept(TOK.kwd_continue) then return parser.out(false) end

	local ok, list = parser.one_or_more(argument)

	return true, {
		id = TOK.continue_stmt,
		text = 'continue',
		span = ok and Span:merge(span, list[#list].span) or span,
		children = ok and list or {},
	}
end

---@brief Syntax rule for `delete` statement
delete_stmt = function(span)
	if not parser.accept(TOK.kwd_delete) then return parser.out(false) end

	---`delete` var1 var2 ... etc
	local ok, list = parser.one_or_more(argument)
	if not ok then
		parser.ast_error(parser.t(), 'argument')
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

statement = function()
	return parser.any_of({
		TOK.line_ending,
		if_stmt,
		subroutine,
		gosub_stmt,
		delete_stmt,
		break_stmt,
		continue_stmt,
		stop_stmt,
		command,
	}, {
		TOK.line_ending,
		'if',
		'delete',
		'break',
		'continue',
		'stop',
		TOK.command,
	}, false)
end

---@brief Syntax rule for a list of statements
program = function()
	local span = parser.t().span
	local ok, statements = parser.zero_or_more(statement)

	local pgm = {
		id = TOK.program,
		text = '',
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
