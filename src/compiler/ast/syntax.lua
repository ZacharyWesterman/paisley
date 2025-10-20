local parser = require 'src.compiler.ast.parser'

local function argument()
	return parser.any_of({
		TOK.text
		-- string,
	}, {
		TOK.text,
		TOK.string,
	})
end

local function command()
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

local program

local function else_stmt(span)
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


local function if_stmt(span)
	if not parser.accept(TOK.kwd_if) then return parser.out(false) end

	--Any missing syntax after this is invalid
	local node = {
		id = TOK.if_stmt,
		text = 'if',
		span = span,
		children = {},
	}

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

local function statement()
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
