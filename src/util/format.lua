require 'src.compiler.lex'
require 'src.compiler.syntax'

parse_error = function(msg)
	--ignore errors
end

return function(text, indent_text)
	local output_text = ''
	local scopes = {}
	local scope_enter = {
		[TOK.string_open] = true,
		[TOK.paren_open] = true,
		[TOK.command_open] = true,
		[TOK.expr_open] = true,
		[TOK.index_open] = true,
	}
	local scope_exit = {
		[TOK.string_close] = true,
		[TOK.paren_close] = true,
		[TOK.command_close] = true,
		[TOK.expr_close] = true,
		[TOK.index_close] = true,
	}

	local indent_enter = {
		[TOK.kwd_then] = true,
		[TOK.kwd_else] = true,
		[TOK.kwd_do] = true,
		[TOK.kwd_try] = true,
		[TOK.kwd_catch] = true,
		[TOK.kwd_function] = true,
		[TOK.paren_open] = true,
		[TOK.command_open] = true,
		[TOK.expr_open] = true,
		[TOK.index_open] = true,
	}
	local indent_exit = {
		[TOK.kwd_else] = true,
		[TOK.kwd_elif] = true,
		[TOK.kwd_end] = true,
		[TOK.kwd_catch] = true,
		[TOK.paren_close] = true,
		[TOK.command_close] = true,
		[TOK.expr_close] = true,
		[TOK.index_close] = true,
	}

	local nospace_expr_before = {
		[TOK.paren_open] = true,
		[TOK.command_open] = true,
		[TOK.op_comma] = true,
		[TOK.index_open] = true,
	}
	local nospace_expr_after = {
		[TOK.op_concat] = true,
	}

	local indent = 0
	local last_token = { id = TOK.line_ending }
	for token in Lexer(text, nil, true) do
		if scope_exit[token.id] then
			table.remove(scopes)
		end
		if indent_exit[token.id] then
			indent = math.max(0, indent - 1)
		end

		if last_token.id == TOK.line_ending and last_token.text ~= ';' then
			output_text = output_text .. indent_text:rep(indent)
		elseif (
				last_token.id ~= TOK.line_ending and
				token.id ~= TOK.line_ending and
				not scope_enter[last_token.id] and
				not scope_exit[token.id] and
				not (scopes[#scopes] == TOK.string_open and token.id ~= TOK.string_open) and
				not (
					(
						scopes[#scopes] == TOK.expr_open or
						scopes[#scopes] == TOK.paren_open or
						scopes[#scopes] == TOK.index_open
					) and
					(
						nospace_expr_before[token.id] or
						nospace_expr_after[last_token.id]
					)
				)
			) then
			output_text = output_text .. ' '
		end

		if scope_enter[token.id] then
			table.insert(scopes, token.id)
		end
		if indent_enter[token.id] then
			indent = indent + 1
		end

		output_text = output_text .. token.text
		last_token = token
	end

	return output_text
end
