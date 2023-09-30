require "lex"
require "syntax"

_tokens = {}
lexer = lex('let x = {3.123 * (5 + 3)}')

for t in lexer do
	table.insert(_tokens, t)
end

syntax(_tokens)
