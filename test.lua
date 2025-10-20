require 'src.compiler.lex'

function Parser(text, filename)
	local lexer = Lexer(text, filename)
	local token, last_token

	local function nextsym()
		last_token = token
		token = lexer()
	end

	local function accept(symbol)
		local ok, node
		if not token then return false, token end

		if type(symbol) == 'function' then
			ok, node = symbol(token.span)
		else
			ok, node = (token and token.id == symbol), token
			if ok then nextsym() end
		end

		return ok, node
	end

	local function ast_error(symbol, valid_tokens)
		local error_msg = 'Unexpected token.'
		local list = {}

		if type(symbol) == 'table' then symbol = symbol[1] end
		if not symbol then
			error_msg = 'Unexpected EOF.'
		elseif type(symbol) ~= 'function' then
			error_msg = 'Unexpected token <' .. token_text(symbol) .. '>.'
		end

		if valid_tokens then
			if type(valid_tokens) ~= 'table' then valid_tokens = { valid_tokens } end

			for i = 1, #valid_tokens do
				if type(valid_tokens[i]) == 'string' then
					table.insert(list, '`' .. valid_tokens[i] .. '`')
				else
					table.insert(list, '<' .. token_text(valid_tokens[i]) .. '>')
				end
			end
		end

		if #list > 0 then
			local last = table.remove(list)
			error_msg = error_msg .. ' Expected '
			if #list > 0 then
				error_msg = error_msg .. std.join(list, ', ') .. ' or '
			end
			error_msg = error_msg .. last .. '.'
		end

		parse_error((symbol or token or last_token).span, error_msg, filename)
	end

	local function expect(symbol, valid_tokens)
		local ok, node = accept(symbol)
		if not ok then
			ast_error(token.id, valid_tokens or { symbol })
		end
		return ok, node
	end

	local function skip(symbol)
		while accept(symbol) do
			--
		end
	end

	local function any_of(symbol_list)
		local ok, node = false, token
		for i = 1, #symbol_list do
			ok, node = accept(symbol_list[i])
			if ok then break end
		end
		return ok, node
	end

	local function zero_or_more(symbol)
		local list = {}
		local ok, node = accept(symbol)
		while ok do
			table.insert(list, node)
			ok, node = accept(symbol)
		end
		return true, list
	end

	local function one_or_more(symbol)
		local ok, list = zero_or_more(symbol)
		if #list == 0 then ok = false end
		return ok, list
	end

	local function expect_list(symbols, skip_symbol)
		local list = {}
		for i = 1, #symbols do
			if skip_symbol then skip(skip_symbol) end

			local symbol = symbols[i]
			if type(symbol) ~= 'table' then symbol = { symbol } end

			local ok, node = any_of(symbol)
			if not ok then
				return false, list
			end

			table.insert(list, node)
		end
		return true, list
	end

	local function placeholder()
		error('COMPILER ERROR: Missing rule definition.')
		return false, token
	end

	--SYNTAX RULES

	local function argument()
		return accept(TOK.text)
	end

	local function command()
		local ok, arguments = one_or_more(argument)
		if not ok then return false, token end

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

	local program = placeholder

	local function else_stmt(span)
		if not accept(TOK.kwd_else) then return false, token end

		---`else` program `end`
		local ok, list = expect_list({ program, TOK.kwd_end }, TOK.line_ending)

		return ok, list[1]
	end


	local function if_stmt(span)
		if not accept(TOK.kwd_if) then return false, token end

		--Any missing syntax after this is invalid
		local node = {
			id = TOK.if_stmt,
			text = 'if',
			span = span,
			children = {},
		}

		local ok, list = expect_list({
			argument,
			{ TOK.kwd_then },
			program,
			{ TOK.kwd_end, else_stmt },
		}, TOK.line_ending)

		node.children = list

		return ok, node
	end

	local function statement()
		local ok, node = any_of({
			TOK.line_ending,
			command,
			if_stmt,
		})

		return ok, node
	end

	program = function()
		local span = token.span
		local ok, statements = zero_or_more(statement)

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

	return function()
		nextsym()
		local ok, node = program()
		return node
	end
end

local program = [[
if 1 then print a else print b end
]]

local parse = Parser(program)

local ast = parse()
print_tokens_recursive(ast)
