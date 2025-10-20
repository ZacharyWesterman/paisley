local p = require 'src.compiler.ast.parser'
local parse = require 'src.compiler.ast.syntax'

function SyntaxParser(tokens, file)
	p.set_token_list(tokens, file)

	return {
		fold = function() end, --KEPT FOR COMPATIBILITY
		get = function()
			return { parse() }
		end,
	}
end
