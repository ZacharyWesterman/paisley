require "stdlib"
require "json"

require "lex"
require "syntax"
require "closest_word"
require "fold_constants"
require "semantics"
require "codegen"

COMPILER_DEBUG = true

local expression = io.read()

--[[
	Command format is a string array, each element formatted as follows:
	"COMMAND_NAME:RETURN_TYPE"
	Where RETURN_TYPE is a Paisley data type, not a Lua type.

	Paisley types are one of the following:
		null
		boolean
		number
		string
		array
		any

	Note that this IS case-sensitive!
]]
ALLOWED_COMMANDS = {
	"print:null",
	"near:boolean",
}

if ALLOWED_COMMANDS then
	local cmds, i = {}
	for i = 1, #ALLOWED_COMMANDS do
		local c = std.split(ALLOWED_COMMANDS[i], ':')
		if not c[2] then c[2] = 'any' end
		cmds[c[1]] = c[2]
	end
	ALLOWED_COMMANDS = cmds
end

-- print(expression)
local lexer = Lexer(expression)
local t
local tokens = {}
for t in lexer do table.insert(tokens, t) end --Iterate to get tokens.

local parser = SyntaxParser(tokens)
while parser.fold() do end --Iterate on the syntax tree. Follows iterator-like behavior.
print_tokens_recursive(parser.get()[1])

--Analyze the AST and check for any errors
local root = SemanticAnalyzer(parser.get())

--Print the AST
print_tokens_recursive(root)

print('--------------------------')
print('Generating bytecode')
print('--------------------------')
--Generate instruction representation
local bytecode = generate_bytecode(root)

print_bytecode(bytecode)
-- output(json.stringify(bytecode), 1)
