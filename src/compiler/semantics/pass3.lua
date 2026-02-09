local synonyms = require "src.compiler.semantics.synonyms"

local labels = {}

return {
	set = function(_labels)
		labels = _labels
	end,

	enter = {
		[TOK.func_call] = {
			--Restructure function calls
			function(token, file)
				--[[minify-delete]]
				if LANGUAGE_SERVER then return end
				--[[/minify-delete]]

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
				--[[minify-delete]]
				if LANGUAGE_SERVER then return end
				--[[/minify-delete]]

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
		},

		[TOK.subroutine] = {
			--Make sure that comment annotations exactly match what the subroutine actually returns.
			function(token, file)
				if not token.tags or not token.tags.returns then return end

				local sig = token.tags.returns.type
				if not token.type then
					local msg = 'Comment annotation indicates a return type of `' ..
						TYPE_TEXT(sig) .. '` but a return type was not deduced.'
					parse_warning(token.span, msg, file)
					return
				end

				if not EXACT_TYPE(sig, token.type) then
					local msg = 'Comment annotation indicates a return type of `' ..
						TYPE_TEXT(sig) .. '` but actual return type is `' .. TYPE_TEXT(token.type) .. '`.'
					parse_warning(token.span, msg, file)
				end
			end,
		},

		[TOK.gosub_stmt] = {
			--Make sure that param types line up with the comment annotations.
			function(token, file)
				local name = token.children[1].text
				local sub = labels[name]
				if not sub or not sub.tags or not sub.tags.params then return end

				for i, param in ipairs(sub.tags.params) do
					local arg = token.children[i + 1]
					local arg_type = (arg and arg.type) or TYPE_NULL

					if not SIMILAR_TYPE(param.type, arg_type) then
						local msg, span
						if arg then
							span = arg.span
							msg = 'Argument ' .. i .. ' of "' .. name .. '" expected `' .. TYPE_TEXT(param.type) ..
								'` but got `' .. TYPE_TEXT(arg_type) .. '`.'
						else
							span = token.span
							msg = 'Missing argument ' .. i ..
								' of "' .. name .. '", expected `' .. TYPE_TEXT(param.type) .. '`.'
						end
						parse_warning(span, msg, file)
					end
				end
			end,
		},
	},

	exit = {},

	finally = function() end,
}
