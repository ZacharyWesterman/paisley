require 'src.compiler.lex'
require 'src.compiler.syntax'
require 'src.shared.json'

local program = [[
match 1 do
	if a then end
else
	c
end
]]

local tokens = {}
local lexer = Lexer(program)
for i in lexer do
	table.insert(tokens, i)
end

local parse = SyntaxParser(tokens).get

local ast = parse()
print_tokens_recursive(ast[1])
