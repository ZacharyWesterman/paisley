require "lex"
require "syntax"

_tokens = {}

local expression = io.read()

if expression == '' then
	parse_error(0, 0, 'Program contains no text')
end

-- print(expression)
lexer = lex(expression)

for t in lexer do
	table.insert(_tokens, t)
end

for _, t in pairs(syntax(_tokens)) do
	print_tokens_recursive(t)
end
