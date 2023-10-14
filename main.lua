require "stdlib"
require "lex"
require "syntax"
require "closest_word"
require "fold_constants"
require "semantics"
require "codegen"

local expression = io.read()

-- print(expression)
local lexer = Lexer(expression)
local t
local tokens = {}
for t in lexer do table.insert(tokens, t) end --Iterate to get tokens.

local parser = SyntaxParser(tokens)
while parser.fold() do end --Iterate on the syntax tree. Follows iterator-like behavior.

--Analyze the AST and check for any errors
local root = SemanticAnalyzer(parser.get())

--Print the AST
print_tokens_recursive(root)

print('--------------------------')
print('Generating bytecode')
print('--------------------------')
--Generate instruction representation
local bytecode = generate_bytecode(root)
