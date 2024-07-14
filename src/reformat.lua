require "src.compiler.lex"

local text = ''
local indent_text = '  '
local indent = 0
local found_subroutine = false
local line_ending_ct = 0

local indent_kwds = {
	[TOK.kwd_then] = true,
	[TOK.kwd_else] = true,
	[TOK.kwd_do] = true,
}

local dedent_kwds = {
	[TOK.kwd_end] = true,
	[TOK.kwd_else] = true,
	[TOK.kwd_elif] = true,
}

for token in Lexer(V1) do
	if dedent_kwds[token.id] then
		indent = math.max(0, indent - 1)
		text = text .. '\n' .. indent_text:rep(indent)
	end

	if token.id ~= TOK.line_ending then
		text = text .. token.text .. ' '
		line_ending_ct = 0
	else
		line_ending_ct = line_ending_ct + 1
		if line_ending_ct < 2 then
			text = text .. '\n' .. indent_text:rep(indent)
		end
	end

	if indent_kwds[token.id] then
		indent = indent + 1
		text = text .. '\n' .. indent_text:rep(indent)
	end

	if found_subroutine then
		indent = indent + 1
		text = text .. '\n' .. indent_text:rep(indent)
		found_subroutine = false
	end

	if token.id == TOK.kwd_subroutine then found_subroutine = true end
end

print(text)
