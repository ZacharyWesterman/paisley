require "lex"
require "syntax"
require "semantics"

local expression = io.read()

if expression == '' then
	parse_error(0, 0, 'Program contains no text')
end

-- print(expression)
local lexer = Lexer(expression)
local t
local tokens = {}
for t in lexer do table.insert(tokens, t) end --Iterate to get tokens.

local parser = SyntaxParser(tokens)
while parser.fold() do end --Iterate on the syntax tree. Follows iterator-like behavior.

--Print the AST
local _
for _, t in pairs(parser.get()) do
	print_tokens_recursive(t)
end

--Analyze the AST and check for any errors
local analyzer = SemanticAnalyzer(parser.get())
