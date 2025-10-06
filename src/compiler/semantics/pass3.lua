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
	},

	exit = {},

	finally = function() end,
}
