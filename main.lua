require "lex"
require "syntax"

_tokens = {}

local expression = io.read()

-- print(expression)
lexer = lex(expression)

for t in lexer do
	table.insert(_tokens, t)
end

syntax(_tokens)
