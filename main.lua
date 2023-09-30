require "lex"
require "syntax"

_tokens = {}
lexer = lex('let x = {1 + {a}}')

for t in lexer do
	table.insert(_tokens, t)
end

syntax(_tokens)
