require 'src.compiler.lex'
require 'src.compiler.syntax'

local errored = false
parse_error = function(msg)
	errored = true
end

return function(text)
	errored = false

	local lexer = Lexer(text, nil, true)
	local tokens = {}
	for i in lexer do table.insert(tokens, i) end

	local parser = SyntaxParser(tokens)
	local ast = parser()

	--Just spit out the input text if the AST had an error.
	if errored then return text end

	local gen_text

	local rules = {
		[TOK.func_call] = function(node)
			local t = node.text .. '('
			for i = 1, #node.children do
				if i > 1 then t = t .. ', ' end
				t = t .. gen_text(node.children[i])
			end
			return t .. ')'
		end,
	}

	gen_text = function(node)
		if rules[node.id] then
			return rules[node.id](node)
		end

		local t = node.text or ''
		if node.children then
			for i = 1, #node.children do
				t = t .. gen_text(node.children[i])
			end
		end
		return t
	end

	local output_text = gen_text(ast)
	return output_text
end
