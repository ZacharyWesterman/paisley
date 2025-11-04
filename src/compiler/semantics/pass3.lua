local synonyms = require "src.compiler.semantics.synonyms"

return {
	enter = {
		[TOK.func_call] = {
			--Restructure function calls
			function(token, file)
				if token.text:sub(1, 1) == '\\' then return end

				if synonyms[token.text] then
					--Handle synonyms (functions that are actually other functions in disguise)
					synonyms[token.text](token)
				end
			end,
		},

		[TOK.ternary] = {
			--Optimize ternaries away if possible
			function(token, file)
				local lhs, rhs = token.children[2].value, token.children[3].value

				if lhs == true and rhs == false then
					token.id = TOK.func_call
					token.text = 'bool'
					token.children = { token.children[1] }
				elseif lhs == false and rhs == true then
					token.id = TOK.boolean
					token.text = 'not'
					token.children = { token.children[1] }
				end
			end,
		},


		[TOK.scope_stmt] = {
			--Convert scope blocks into regular program blocks.
			--At this point, all semantic analysis is done for them.
			function(token, file)
				token.id = TOK.program
			end,
		}
	},

	exit = {},

	finally = function() end,
}
