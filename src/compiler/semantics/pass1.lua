local function break_continue(token, file)
	if #token.children == 0 then
		token.children = { {
			id = TOK.lit_number,
			text = '1',
			value = 1,
			span = token.span,
			children = {},
		} }
		return
	end

	local val = tonumber(token.children[1].text, 10)
	if #token.children > 1 or val == nil or val < 1 then
		parse_error(token.span, 'Only a constant positive integer is allowed as a parameter for "' .. token.text ..
			'"', file)
	end
end

--Make a list of all subroutines, and check that return statements are only in subroutines
local labels = {}
local inside_sub = 0
local function subroutine_enter(token, file)
	if token.id == TOK.subroutine then
		inside_sub = inside_sub + 1

		local label = token.text
		local prev = labels[label]
		if prev ~= nil --[[minify-delete]] and not _G['ALLOW_SUBROUTINE_ELISION'] and not prev.allow_elision --[[/minify-delete]] then
			-- Don't allow tokens to be redeclared
			parse_error(token.span,
				'Redeclaration of subroutine "' ..
				label .. '" (previously declared on line ' .. prev.span.from.line ..
				', col ' .. prev.span.from.col .. ')', file)
		end

		if #token.children == 0 then
			token.ignore = true
		end

		--[[minify-delete]]
		if _G['ELIDE_LINES'][token.span.from.line] then
			token.allow_elision = true
		end
		--[[/minify-delete]]

		labels[label] = token
	else
		if inside_sub < 1 then
			parse_error(token.span, 'Return statements can only be inside subroutines', file)
		end
	end
end
local function subroutine_exit(token, file)
	if token.id == TOK.subroutine then
		inside_sub = inside_sub - 1
	end
end

--Resolve all subroutine aliases
--Unlike other structures, these do respect scope.
local aliases = { {} }

--[[minify-delete]]
if _G['REPL'] then
	aliases = { ALIASES_TOPLEVEL }
end
--[[/minify-delete]]

local function aliases_enter(token, file)
	if token.id == TOK.alias_stmt then
		--Set the alias
		local c = token.children[1]
		aliases[#aliases][token.children[2].text] = c.text

		--If alias refers to a subroutine that doesn't exist, error.
		if not labels[c.text] then
			local msg = 'Subroutine `' .. c.text .. '` not declared anywhere'
			local guess = closest_word(c.text, labels, 4)
			if guess ~= nil and guess ~= '' then
				msg = msg .. ' (did you mean "' .. guess .. '"?)'
			end
			parse_error(c.span, msg, file)
		end
	elseif token.id == TOK.gosub_stmt then
		--Check for an alias that matches
		for i = #aliases, 1, -1 do
			local c = token.children[1]
			local a = aliases[i][c.text]
			if a then
				--If one matches, use it.
				c.text = a
				break
			end
		end
	else
		table.insert(aliases, {})
	end
end
local function aliases_exit(token, file)
	if token.id ~= TOK.alias_stmt and token.id ~= TOK.gosub_stmt then
		table.remove(aliases)
	end
end

--Resolve all macro references
local macros = { {} }

--[[minify-delete]]
if _G['REPL'] then
	macros = MACROS_TOPLEVEL
end
--[[/minify-delete]]

local function get_macro(name)
	for i = #macros, 1, -1 do
		if macros[i][name] then
			return macros[i][name]
		end
	end
	return nil
end

local tok_level = 0
local scope_ids = { 0 }
local function pop_scope(token, file)
	if token.id == TOK.macro then
		macros[#macros][token.text] = {
			level = tok_level,
			node = token.children[1]
		}
	elseif token.id == TOK.macro_ref then
		local macro = get_macro(token.text)
		if not macro then
			parse_error(token.span, 'Macro "' .. token.text .. '" is not defined in the current scope', file)
		else
			--Macro is defined, so replace it with the appropriate node
			for _, i in ipairs({ 'text', 'span', 'id', 'value', 'type', 'children' }) do
				token[i] = macro.node[i]
			end
		end
	else
		--Make sure macros are only referenced in the appropriate scope, never outside the scope they're defined.
		table.remove(macros)
		tok_level = tok_level - 1
		table.remove(scope_ids)
	end
end

local function push_scope(token, file)
	if token.id ~= TOK.macro and token.id ~= TOK.macro_ref then
		if token.id == TOK.else_stmt or token.id == TOK.elif_stmt then
			--Wipe the current scope to prevent macro references from leaking into the else block
			table.remove(macros)
			table.insert(macros, {})
		end
		table.insert(macros, {})
		--Make sure macros are only referenced in the appropriate scope, never outside the scope they're defined.
		tok_level = tok_level + 1
		table.insert(scope_ids, scope_ids[#scope_ids] + 1)
	end
end

--Tidy up WHILE loops and IF/ELIF statements (replace command with cmd contents)
local function loop_cleanup(token, file)
	if token.children[1].id == TOK.command then
		if #token.children[1].children > 1 then
			parse_error(token.span, 'Too many parameters passed to "' .. token.text .. '" statement', file)
		end
		token.children[1] = token.children[1].children[1]
	end
end


return {
	enter = {
		[TOK.variable] = {
			--Convert @DIGIT variables into @[DIGIT] indexes
			function(token, file)
				if #token.text > 1 and token.text:sub(1, 1) == '@' then
					local index = tonumber(token.text:sub(2))
					if index < 1 then
						parse_error(token.span, 'Indexes start at 1', file)
					end

					token.id = TOK.index
					token.children = {
						{
							span = token.span,
							id = TOK.variable,
							text = '@',
							children = {},
						},
						{
							span = token.span,
							id = TOK.lit_number,
							text = tostring(index),
							value = index,
							children = {},
						}
					}
				end
			end,

			--Set the scope of the variable
			function(token, file)
				token.scope = scope_ids[#scope_ids]
			end,
		},

		--BREAK and CONTINUE statements are only allowed to have up to a single CONSTANT INTEGER operand
		[TOK.break_stmt] = { break_continue },
		[TOK.continue_stmt] = { break_continue },

		[TOK.delete_stmt] = {
			--Make sure "delete" statements only have text params. deleting expressions that resolve to variable names is a recipe for disaster.
			function(token, file)
				---@type Token[]
				local kids = token.children
				if not kids then return end
				if #kids[1].children > 0 then kids = kids[1].children end
				for i = 1, #kids do
					if kids and kids[i].id ~= TOK.text then
						parse_error(kids[i].span, 'Expected only variable names after "delete" keyword', file)
					end
				end
				token.children = kids
			end,
		},

		[TOK.subroutine] = {
			subroutine_enter,
			aliases_enter,
			push_scope,
		},

		[TOK.scope_stmt] = { push_scope },

		[TOK.return_stmt] = { subroutine_enter },

		[TOK.gosub_stmt] = {
			--Reduce subroutine references
			function(token, file)
				if token.children[1].id == TOK.command then
					token.children = token.children[1].children
				end
			end,

			aliases_enter,
		},

		[TOK.alias_stmt] = {
			--Split up subroutine aliases that end with an asterisk
			function(token, file)
				local l, a = token.children[1], token.children[2]
				local label, alias = l.text, a.text

				if label:sub(#label) == '*' and alias:match('%*') then
					label = label:sub(1, #label - 1)
					local aliases = {}
					for i, _ in pairs(labels) do
						if i:sub(1, #label) == label and i ~= label then
							table.insert(aliases, {
								id = TOK.alias_stmt,
								text = 'using',
								span = token.span,
								children = {
									{
										id = TOK.text,
										span = l.span,
										text = i,
										children = {},
									},
									{
										id = TOK.text,
										span = a.span,
										text = alias:gsub('%*', i:sub(#label + 1)),
										children = {},
									}
								},
							})
						end
					end

					token.id = TOK.program
					token.children = aliases
				end
			end,

			aliases_enter,
		},

		[TOK.if_stmt] = {
			aliases_enter,
			push_scope,
			loop_cleanup,
		},
		[TOK.while_stmt] = {
			aliases_enter,
			push_scope,
			loop_cleanup,
		},
		[TOK.for_stmt] = {
			aliases_enter,
			push_scope,
			--Tidy up FOR loops (replace command with cmd contents)
			function(token, file)
				if token.children[2].id == TOK.command then
					if #token.children[2].children > 1 then
						token.children[2].id = TOK.array_concat
					else
						for _, i in ipairs({ 'text', 'span', 'id', 'value', 'type' }) do
							token.children[2][i] = token.children[2].children[1][i]
						end
						token.children[2].children = token.children[2].children[1].children
					end
				end

				--Don't automatically set var type to "string", let it deduce.
				if token.children[1].id == TOK.text then
					token.children[1].id = TOK.var_assign
					token.children[1].value = nil
					token.children[1].type = nil
				end
			end,
		},
		[TOK.kv_for_stmt] = {
			aliases_enter,
			push_scope,
			--Tidy up FOR loops (replace command with cmd contents)
			function(token, file)
				if token.children[3].id == TOK.command then
					if #token.children[3].children > 1 then
						token.children[3].id = TOK.array_concat
					else
						for _, i in ipairs({ 'text', 'span', 'id', 'value', 'type' }) do
							token.children[3][i] = token.children[3].children[1][i]
						end
						token.children[3].children = token.children[3].children[1].children
					end
				end

				--Don't automatically set var types to "string", let them deduce.
				for i = 1, 2 do
					if token.children[i].id == TOK.text then
						token.children[i].id = TOK.var_assign
						token.children[i].value = nil
						token.children[i].type = nil
					end
				end
			end,
		},
		[TOK.else_stmt] = {
			aliases_enter,
			push_scope,
		},
		[TOK.elif_stmt] = {
			aliases_enter,
			push_scope,
			loop_cleanup,
		},
		[TOK.match_stmt] = {
			aliases_enter,
			push_scope,
		},

		[TOK.string_open] = {
			--Prep plain (non-interpolated) strings to allow constant folding
			function(token, file)
				if #token.children > 0 then
					if token.children[1].id == TOK.text and #token.children == 1 then
						token.value = token.children[1].text
						token.children = {}
					end
				elseif not token.value then
					token.value = ''
				end
			end,
		},

		[TOK.boolean] = {
			--Check for variable existence by var name, not value
			function(token, file)
				local ch = token.children[1]
				if token.text == 'exists' and ch.id == TOK.variable then
					ch.id = TOK.string_open
					ch.value = ch.text
					ch.type = _G['TYPE_STRING']
				end
			end,
		},

		[TOK.text] = {
			--Prep text to allow constant folding
			function(token, file)
				local val = tonumber(token.text)
				if val then
					token.value = val
					token.type = _G['TYPE_NUMBER']
				else
					token.value = token.text
					token.type = _G['TYPE_STRING']
				end
			end,
		},

		[TOK.let_stmt] = {
			--Make variable assignment make sense, removing quirks of AST generation.
			function(token, file)
				--Make sure there are no redundant variable assignments
				if #token.children[1].children > 0 then
					local vars = { [token.children[1].text] = true }
					for i = 1, #token.children[1].children do
						local child = token.children[1].children[i]
						if child.text ~= '_' and vars[child.text] then
							parse_error(child.span,
								'Redundant variable `' ..
								child.text ..
								'` in group assignment. To indicate that this element should be ignored, use an underscore for the variable name.',
								file)
						end
						vars[child.text] = true
					end
				end
			end
		},

		[TOK.var_assign] = {
			--Set the scope of the variable assignment
			function(token, file)
				token.scope = scope_ids[#scope_ids]
			end,
		},

		[TOK.uncache_stmt] = {
			--Make sure `break cache` refers to an existing subroutine
			function(token, file)
				local label = token.children[1].text

				if labels[label] == nil then
					local msg = 'Subroutine `' .. label .. '` not declared anywhere'
					local guess = closest_word(label, labels, 4)
					if guess ~= nil and guess ~= '' then
						msg = msg .. ' (did you mean "' .. guess .. '"?)'
					end
					parse_error(token.children[1].span, msg, file)
				else
					token.ignore = labels[label].ignore
				end
			end,
		},

		[TOK.func_call] = {
			--Replace special function calls "\sub_name(arg1,arg2)" with "${gosub sub_name {arg1} {arg2}}"
			function(token, file)
				if token.text:sub(1, 1) ~= '\\' then return end

				--If function name begins with backslash, it's actually a gosub.

				---@type Token[]
				table.insert(token.children, 1, {
					id = TOK.text,
					text = token.text:sub(2),
					span = token.span,
					type = TYPE_STRING,
					value = token.text:sub(2),
					children = {},
				})

				token.text = '${'
				token.id = TOK.inline_command
				token.children = { {
					id = TOK.gosub_stmt,
					text = 'gosub',
					span = token.span,
					children = token.children,
				} }
			end,
		},
	},

	exit = {
		[TOK.subroutine] = {
			subroutine_exit,
			aliases_exit,
			pop_scope,
		},
		[TOK.scope_stmt] = { pop_scope },
		[TOK.return_stmt] = { subroutine_exit },

		[TOK.if_stmt] = {
			aliases_exit,
			pop_scope,
		},
		[TOK.while_stmt] = {
			aliases_exit,
			pop_scope,
		},
		[TOK.for_stmt] = {
			aliases_exit,
			pop_scope,
		},
		[TOK.kv_for_stmt] = {
			aliases_exit,
			pop_scope,
			--Make sure key-value for loops always have some mutation of `pairs()` or `chunk()` in the expression.
			--An array literal that contains pairs (e.g. `((1,2), (3,4))`) is also valid.
			function(token, file)
				local node = token.children[3]

				if node.id == TOK.lit_array then
					print_token(node)
					--An array literal that looks like a pairs() result is totally valid.
					local ok = true
					for _, i in pairs(node.value) do
						if std.type(i) ~= 'array' or #i == 0 then
							ok = false
							break
						end
					end
					if ok then return end
				end

				while true do
					if node.id == TOK.func_call and (node.text == 'pairs' or node.text == 'chunk') then
						if node.text == 'chunk' then
							--Make sure that the second parameter to chunk() is exactly 2.
							node = node.children[2]
							if node.value ~= 2 then
								parse_error(node.span,
									'The second parameter to `chunk()` in key-value for loops must be exactly 2',
									file)
							end
						end

						return
					end

					if #node.children == 0 then break end
					node = node.children[1]
					if not node then break end
				end

				print_tokens_recursive(token)
				parse_error(token.children[3].span,
					'Expression in key-value for loop must contain `pairs()` or `chunk()`', file)
			end,

			--Don't automatically set var type to "string", let it deduce.
			function(token, file)
				for i = 1, 2 do
					if token.children[i].id == TOK.text then
						token.children[i].id = TOK.var_assign
						token.children[i].value = nil
						token.children[i].type = nil
					end
				end
			end,
		},
		[TOK.else_stmt] = {
			aliases_exit,
			pop_scope,
		},
		[TOK.elif_stmt] = {
			aliases_exit,
			pop_scope,
		},
		[TOK.match_stmt] = {
			aliases_exit,
			pop_scope,
		},
		[TOK.macro] = {
			pop_scope,
			--Replace macro definitions with the appropriate node.
			function(token, file)
				local macro_node = token.children[1]
				for _, i in ipairs({ 'text', 'span', 'id', 'value', 'type' }) do
					token[i] = macro_node[i]
				end
				token.children = macro_node.children
			end,
		},
		[TOK.macro_ref] = { pop_scope },
	},

	finally = function()
		--[[minify-delete]]
		if _G['REPL'] then
			for key, value in pairs(aliases[1]) do
				ALIASES_TOPLEVEL[key] = value
			end
		end

		if _G['REPL'] then
			macros = MACROS_TOPLEVEL
		end
		--[[/minify-delete]]

		return labels
	end,
}
