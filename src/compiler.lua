--[[
	This is the Paisley compiler.
	It takes Paisley code and compiles it into bytecode that is easy to interpret and run.
]]

require "src.shared.stdlib"
require "src.shared.json"
require "src.shared.xml"
require "src.shared.closest_word"

require "src.compiler.type_signature"
require "src.compiler.lex"
require "src.compiler.syntax"
require "src.compiler.fold_constants"
require "src.compiler.semantics"
require "src.compiler.codegen"

local expression = V1:gsub('\x0b', '\n')
local file = V2

--[[minify-delete]]
if file == nil and _G['LANGUAGE_SERVER'] then
	file = _G['LSP_FILENAME']
end
--[[/minify-delete]]

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

--[[minify-delete]]
local LFS_INSTALLED, LFS = pcall(require, 'LFS')
local old_working_dir = nil
if LFS_INSTALLED then
	old_working_dir = LFS.currentdir()
	LFS.chdir(_G['WORKING_DIR'])
end
--[[/minify-delete]]

local lexer = Lexer(expression, file)
local t
local tokens = {}
for t in lexer do table.insert(tokens, t) end --Iterate to get tokens.

--[[minify-delete]]
if COMPILER_DEBUG or _G['PRINT_TOKENS'] then
	function print_header(title)
		print('--------------------------')
		print(title)
		print('--------------------------')
	end

	if COMPILER_DEBUG then print_header('Tokens') end
	local i
	for i = 1, #tokens do
		print_token(tokens[i])
	end
end
--[[/minify-delete]]

--[[minify-delete]]
HIDE_ERRORS = _G['SUPPRESS_AST_ERRORS'] --[[/minify-delete]]

local parser = SyntaxParser(tokens, file)
while parser.fold() do end --Iterate on the syntax tree. Follows iterator-like behavior.

--[[minify-delete]]
HIDE_ERRORS = false

if _G['PRINT_AST'] and not _G['AST_AFTER_SEMANTIC'] then
	print_tokens_recursive(parser.get()[1])
	return
end
--[[/minify-delete]]

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
	if _G['AST_AFTER_SEMANTIC'] then
		print_tokens_recursive(root)
	end

	if COMPILER_DEBUG then
		print_header('After Semantic Analysis')
		print_tokens_recursive(root)
	end
	--[[/minify-delete]]

	--Generate instruction representation
	bytecode = generate_bytecode(root, file)
	--[[minify-delete]]
	if COMPILER_DEBUG then
		print_header('Generated Bytecode')
		print_bytecode(bytecode, file)
	end
	--[[/minify-delete]]

	output(json.stringify(bytecode), 1)
end

--[[minify-delete]]
if LFS_INSTALLED then
	LFS.chdir(old_working_dir)
end
--[[/minify-delete]]
