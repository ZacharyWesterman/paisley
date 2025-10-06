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

		-- --[[minify-delete]]
		-- [TOK.boolean] = {
		-- 	--Warn about impossible branches (e.g. {a != b or a != c}, if b != c then this is always true)
		-- 	--Only check if b and c are literals
		-- 	function(token, file)
		-- 		if token.text ~= 'or' then return end

		-- 		local lhs, rhs = token.children[1], token.children[2]

		-- 		if lhs.type ~= TOK.comparison or rhs.type ~= TOK.comparison then return end
		-- 	end,
		-- },
		-- --[[/minify-delete]]
	},

	exit = {},

	finally = function() end,
}
