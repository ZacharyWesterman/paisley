--[[
	This is the Paisley compiler.
	It takes Paisley code and compiles it into bytecode that is easy to interpret and run.
]]

require "src.shared.stdlib"
require "src.shared.json"
require "src.shared.closest_word"

require "src.compiler.lex"
require "src.compiler.syntax"
require "src.compiler.fold_constants"
require "src.compiler.semantics"
require "src.compiler.codegen"

local expression = V1:gsub('\x0b', '\n')
local file = V2

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
ALLOWED_COMMANDS = V3
require "src.shared.builtin_commands"

local lexer = Lexer(expression, file)
local t
local tokens = {}
for t in lexer do table.insert(tokens, t) end --Iterate to get tokens.

--[[minify-delete]]
if COMPILER_DEBUG then
	function print_header(title)
		print('--------------------------')
		print(title)
		print('--------------------------')
	end
	print_header('Tokens')
	local i
	for i = 1, #tokens do
		print_token(tokens[i])
	end
end
--[[/minify-delete]]

local parser = SyntaxParser(tokens, file)
while parser.fold() do end --Iterate on the syntax tree. Follows iterator-like behavior.

if #parser.get() == 0 then
	output("{}", 1)
else
	--[[minify-delete]]
	if COMPILER_DEBUG then
		print_header('AST First Pass')
		print_tokens_recursive(parser.get()[1])
	end
	--[[/minify-delete]]

	--Analyze the AST and check for any errors
	local root = SemanticAnalyzer(parser.get(), file)
	--[[minify-delete]]
	if COMPILER_DEBUG then
		print_header('After Semantic Analysis')
		print_tokens_recursive(root)
	end
	--[[/minify-delete]]

	--Generate instruction representation
	local bytecode = generate_bytecode(root, file)
	--[[minify-delete]]
	if COMPILER_DEBUG then
		print_header('Generated Bytecode')
		print_bytecode(bytecode)
	end
	--[[/minify-delete]]

	output(json.stringify(bytecode), 1)
end
