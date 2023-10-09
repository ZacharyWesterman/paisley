require "lex"
require "syntax"

local expression = io.read()

if expression == '' then
	parse_error(0, 0, 'Program contains no text')
end

-- print(expression)
local lexer = Lexer(expression)
local t
local tokens = {}
for t in lexer do table.insert(tokens, t) end --Iterate to get tokens.

parser = SyntaxParser(tokens)
while parser.fold() do end --Iterate on the syntax tree. Follows iterator-like behavior.


--Print the AST
for _, t in pairs(parser.get()) do
	print_tokens_recursive(t)
end
