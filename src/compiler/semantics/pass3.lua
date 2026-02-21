local synonyms = require "src.compiler.semantics.synonyms"

local labels = {}

local function run_debug_fn(token, file, dbg)
	--Deep copy child ast nodes before passing to debug function.
	--We DON'T want those functions to be able to actually change compilation!
	local tokens = {}
	local function deep_copy(data)
		if type(data) ~= 'table' then return data end
		local new = setmetatable({}, getmetatable(data))
		for key, val in pairs(data) do
			new[key] = deep_copy(val)
		end

		--If we're copying an ast node, inject helper functions in there.
		if new.span and new.type then
			new.info = function(self, msg)
				parse_info(self.span, msg, file)
			end

			new.type.tostring = function(self)
				return TYPE_TEXT(self)
			end
			new.type.is_exactly = function(self, rhs)
				if type(rhs) == 'string' then
					rhs = SIGNATURE(rhs)
				elseif type(rhs) ~= 'table' then
					return false
				end
				return EXACT_TYPE(self, rhs)
			end
			new.type.is_subset_of = function(self, rhs)
				if type(rhs) == 'string' then
					rhs = SIGNATURE(rhs)
				elseif type(rhs) ~= 'table' then
					return false
				end
				return TYPE_IS_SUBSET(rhs, self)
			end
			new.type.is_superset_of = function(self, rhs)
				if type(rhs) == 'string' then
					rhs = SIGNATURE(rhs)
				elseif type(rhs) ~= 'table' then
					return false
				end
				return TYPE_IS_SUBSET(self, rhs)
			end
			new.is_const = new.value ~= nil or new.id == TOK.lit_null
		end

		return new
	end
	for i = 2, #token.children do
		table.insert(tokens, deep_copy(token.children[i]))
	end

	--Run the debug function
	--(arg_token_list, warn, info, json)
	local success, error_msg = pcall(
		dbg.fn,
		tokens,
		function(msg) parse_info(token.span, msg, file) end,
		require 'src.shared.json'
	)
	if not success then
		parse_info(dbg.span, 'Error in @debug annotation: ' .. error_msg, dbg.file)
	end
end

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

		[TOK.function_def] = {
			--Make sure that comment annotations exactly match what the function actually returns.
			function(token, file)
				if not token.tags or not token.tags.returns then return end

				local sig = token.tags.returns.type
				local tp = token.type or TYPE_NULL

				if not TYPE_IS_SUBSET(sig, tp) then
					local msg = 'Comment annotation indicates a return type of `' ..
						TYPE_TEXT(sig) .. '` but actual return type is `' .. TYPE_TEXT(tp) .. '`.'
					parse_warning(token.span, msg, file)
				end
			end,
		},

		[TOK.call_stmt] = {
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

			--[[minify-delete]]
			--Process any @debug annotations for this function call
			function(token, file)
				local name = token.children[1].text
				local sub = labels[name]
				if not sub or not sub.tags or not sub.tags.debug then return end

				run_debug_fn(token, file, sub.tags.debug)
			end,
			--[[/minify-delete]]
		},

		--[[minify-delete]]
		[TOK.command] = {
			--Process any @debug annotations for this command invocation
			function(token, file)
				if not DEBUG_FUNCS then return end

				--Only process annotation for commands that are known at compile time.
				local cmdname = token.children[1].value
				if not cmdname then return end

				--If no annotation for this command, skip.
				local dbg = DEBUG_FUNCS[cmdname]
				if not dbg then return end

				run_debug_fn(token, file, dbg)
			end,
		},
		--[[/minify-delete]]
	},

	exit = {},

	finally = function() end,
}
