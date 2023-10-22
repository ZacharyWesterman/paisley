--[[
	This is the Paisley compiler.
	It takes Paisley code and compiles it into bytecode that is easy to interpret and run.
]]

require "stdlib"
require "json"

require "lex"
require "syntax"
require "closest_word"
require "fold_constants"
require "semantics"
require "codegen"

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
if ALLOWED_COMMANDS and #ALLOWED_COMMANDS > 0 then
	local cmds, i = {}
	for i = 1, #ALLOWED_COMMANDS do
		local c = std.split(ALLOWED_COMMANDS[i], ':')
		if not c[2] then c[2] = 'any' end
		cmds[c[1]] = c[2]
	end
	ALLOWED_COMMANDS = cmds
else
	ALLOWED_COMMANDS = nil
end

local lexer = Lexer(expression, file)
local t
local tokens = {}
for t in lexer do table.insert(tokens, t) end --Iterate to get tokens.

local parser = SyntaxParser(tokens, file)
while parser.fold() do end --Iterate on the syntax tree. Follows iterator-like behavior.

--Analyze the AST and check for any errors
local root = SemanticAnalyzer(parser.get(), file)

--Generate instruction representation
local bytecode = generate_bytecode(root, file)
output(json.stringify(bytecode), 1)
