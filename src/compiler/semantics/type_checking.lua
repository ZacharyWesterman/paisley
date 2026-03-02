local current_sub
local labels = {}
--[[minify-delete]]
local in_cmd_eval = false
--[[/minify-delete]]
local funcsig



local function command(token, file)
	local ch = token.children[1]

	--function eval is different
	if ch.id == TOK.call_stmt then
		if not token.type then
			local lbl = ch.children[1]
			if labels[lbl.text] then token.type = labels[lbl.text].type end
		end

		return
	end

	if token.id == TOK.inline_command then ch = ch.children[1] end

	--ignore "define" pseudo-command
	if ch.value == 'define' then return end

	if ch.value ~= nil and ch.id ~= TOK.lit_null and token.id == TOK.command then
		if not ALLOWED_COMMANDS[ch.value] and not BUILTIN_COMMANDS[ch.value] then
			--[[minify-delete]]

			--Tell user about incorrect stdout+err capture
			if ch.value == '!?' then
				parse_error(ch.span, 'Unknown shell command "!?" (you probably meant "?!")', file)
			end

			if COERCE_SHELL_CMDS and not RESTRICT_TO_PLASMA_BUILD then
				--If bash extension is enabled, try to run a shell command
				local bashcmd = '='
				if in_cmd_eval then bashcmd = '?' end

				table.insert(token.children, 1, {
					id = TOK.string,
					span = ch.span,
					text = bashcmd,
					value = bashcmd,
					type = TYPE_STRING,
					children = {},
				})
			else
				--[[/minify-delete]]

				--If command doesn't exist, try to help user by guessing the closest match (but still throw an error)
				local msg = 'Unknown command "' .. std.str(ch.value) .. '"'
				local guess = closest_word(std.str(ch.value), ALLOWED_COMMANDS, 4)
				if guess == nil or guess == '' then
					guess = closest_word(std.str(ch.value), BUILTIN_COMMANDS, 4)
				end

				if guess ~= nil and guess ~= '' then
					msg = msg .. ' (did you mean "' .. std.str(guess) .. '"?)'
				end
				parse_error(token.span, msg, file)

				--[[minify-delete]]
			end
			--[[/minify-delete]]
		end

		--[[minify-delete]]
		in_cmd_eval = false
		--[[/minify-delete]]

		if ALLOWED_COMMANDS[ch.value] then
			token.type = ALLOWED_COMMANDS[ch.value]
		else
			token.type = BUILTIN_COMMANDS[ch.value]
		end
	end

	if token.id == TOK.inline_command then token.type = token.children[1].type end
end

local function type_from_value(token)
	if token.value ~= nil or token.id == TOK.lit_null then
		token.type = SIGNATURE(std.deep_type(token.value))
	end
end

local function require_args_op(arg_type)
	local tpstr = (({
		[TYPE_NUMBER] = 'numeric',
		[TYPE_BOOLEAN] = 'boolean',
		[TYPE_STRING] = 'string',
	})[arg_type] or 'UNKNOWN')

	return function(token, file)
		local failed = false
		local args = {}
		for _, child in ipairs(token.children) do
			if child.type then
				table.insert(args, TYPE_TEXT(child.type))
				if not TYPE_IS_SUBSET(child.type, arg_type) then failed = true end
			else
				table.insert(args, 'unknown')
			end
		end

		if failed then
			local op = (token.id == TOK.bitwise and 'bitwise ' or '') .. token.text
			parse_error(
				token.span,
				'Operator `' .. op .. '` expected only ' .. tpstr ..
				' arguments but got (' .. std.join(args, ', ') .. ').',
				file
			)
		end
	end
end


return {
	set = function(new_labels, new_funcsig)
		labels = new_labels
		current_sub = nil
		in_cmd_eval = false
		funcsig = new_funcsig
	end,

	enter = {
		[TOK.function_def] = {
			function(token) current_sub = token.text end,
		},

		[TOK.inline_command] = {
			function() in_cmd_eval = true end,
		},

		[TOK.index] = {
			function(token)
				local indexer = token.children[2]
				if indexer.id == TOK.array_slice and #indexer.children == 1 then
					--Allow unterminated slices inside indexes ONLY.
					indexer.unterminated = true
				end
			end,
		},
	},

	exit = {
		[TOK.command] = { command, },
		[TOK.inline_command] = { command, },

		[TOK.lit_number] = { type_from_value, },
		[TOK.lit_null] = { type_from_value, },
		[TOK.lit_boolean] = { type_from_value, },
		[TOK.lit_array] = { type_from_value, },
		[TOK.lit_object] = { type_from_value, },

		[TOK.return_stmt] = {
			function(token)
				local sub = labels[current_sub]
				if sub then
					local exp_type = nil

					if not token.children or #token.children == 0 then
						exp_type = TYPE_NULL
					elseif token.children[1].type then
						exp_type = token.children[1].type
					end

					if sub.type and exp_type and not SIMILAR_TYPE(exp_type, sub.type) then
						sub.type = MERGE_TYPES(exp_type, sub.type)
					else
						sub.type = exp_type
					end
				end
			end,
		},

		[TOK.function_def] = {
			function() current_sub = nil end,
			function(token)
				if #token.children[1].children == 0 then
					token.type = TYPE_NULL
				end
			end
		},

		[TOK.index] = {
			function(token, file)
				local c2 = token.children[2]
				if c2.id == TOK.array_slice and #c2.children == 1 then
					c2.unterminated = true
					c2.type = TYPE_ARRAY_NUMBER
				end

				local t1, t2 = token.children[1].type, c2.type

				if t1 and not SIMILAR_TYPE(t1, TYPE_INDEXABLE) then
					if token.null_coalesce and token.children[1].value == nil then
						return
					end
					parse_error(token.children[1].span,
						'Cannot index a value of type `' ..
						TYPE_TEXT(t1) .. '`. Type must be `string`, `array`, or `object`', file)
					return
				end

				if t1 and t2 then
					if EXACT_TYPE(t1, TYPE_OBJECT) then
						token.type = TYPE_ANY
					else
						if not SIMILAR_TYPE(t2, TYPE_INDEXER) then
							parse_error(token.children[1].span,
								'Cannot index with a value of type `' ..
								TYPE_TEXT(t2) .. '`. Must be `array[number]` or `number`', file)
							return
						end

						if EXACT_TYPE(t1, TYPE_STRING) then
							token.type = TYPE_STRING
						elseif EXACT_TYPE(t2, TYPE_ANY) then
							--If index is "any", result is either the same type as t1, or the subtype of t1
							token.type = MERGE_TYPES(t1, GET_SUBTYPES(t1))
						elseif SIMILAR_TYPE(t2, TYPE_ARRAY) then
							if HAS_SUBTYPES(t1) then
								token.type = t1
							else
								token.type = ARRAY_FROM_TYPE(t1)
							end
						elseif HAS_SUBTYPES(t1) then
							token.type = GET_SUBTYPES(t1)
						else
							--We don't know what type of array this is, so result of non-const array index has to be "any"
							token.type = TYPE_ANY
						end
					end
				end
			end,
		},

		[TOK.string_open] = {
			function(token)
				token.type = TYPE_STRING
			end,
		},

		[TOK.add] = {
			require_args_op(TYPE_NUMBER),
			function(token) token.type = TYPE_NUMBER end,
		},

		[TOK.negate] = {
			require_args_op(TYPE_NUMBER),
			function(token) token.type = TYPE_NUMBER end,
		},

		[TOK.multiply] = {
			require_args_op(TYPE_NUMBER),
			function(token) token.type = TYPE_NUMBER end,
		},

		[TOK.exponent] = {
			require_args_op(TYPE_NUMBER),
			function(token) token.type = TYPE_NUMBER end,
		},

		[TOK.bitwise] = {
			require_args_op(TYPE_NUMBER),
			function(token) token.type = TYPE_NUMBER end,
		},

		[TOK.boolean] = {
			function(token) token.type = TYPE_BOOLEAN end,
		},

		[TOK.comparison] = {
			function(token) token.type = TYPE_BOOLEAN end,

			function(token, file)
				local c1, c2 = token.children[1], token.children[2]
				if token.text == 'in' then
					if c2.type and not SIMILAR_TYPE(c2.type, TYPE_INDEXABLE) then
						parse_error(
							c2.span,
							'Right operand of `in` expected (array|object) but got (' .. TYPE_TEXT(c2.type) .. ').',
							file
						)
					end
					return
				end

				if token.text == 'like' then
					local c1_invalid = c1.type and not TYPE_IS_SUBSET(c1.type, TYPE_STRING)
					local c2_invalid = c2.type and not TYPE_IS_SUBSET(c2.type, TYPE_STRING)

					if c1_invalid or c2_invalid then
						local c1_tp = c1.type and TYPE_TEXT(c1.type) or 'unknown'
						local c2_tp = c2.type and TYPE_TEXT(c2.type) or 'unknown'
						local span = token.span
						if not c1_invalid then span = c2.span end
						if not c2_invalid then span = c1.span end

						parse_error(
							span,
							'Operator `like` expected arguments of type (string,string) but got (' ..
							c1_tp .. ',' .. c2_tp .. ').',
							file
						)
					end
					return
				end
			end

		},

		[TOK.array_concat] = {
			function(token)
				local tp
				for _, child in ipairs(token.children) do
					if child.type then
						tp = tp and MERGE_TYPES(tp, child.type) or child.type
					end
				end

				token.type = ARRAY_FROM_TYPE(tp or TYPE_ANY)
			end,
		},

		[TOK.concat] = {
			function(token) token.type = TYPE_STRING end,
		},

		[TOK.length] = {
			function(token, file)
				local child = token.children[1]
				if child.type and not SIMILAR_TYPE(child.type, TYPE_COUNTABLE) then
					parse_error(
						child.span,
						'Function `len()` expected an argument of type (array|string) but got (' ..
						TYPE_TEXT(child.type) .. ').',
						file
					)
				end

				token.type = TYPE_NUMBER
			end,
		},

		[TOK.func_call] = {
			function(token, file)
				local signature
				local override_tp

				if TYPESIG[token.id] ~= nil then
					signature = TYPESIG[token.id]
				elseif TYPESIG[token.text] ~= nil then
					signature = TYPESIG[token.text]
					--[[minify-delete]]
					if RESTRICT_TO_PLASMA_BUILD and signature.plasma == false then
						parse_error(token.span, 'The `' .. token.text .. '` function cannot be used in the Plasma build.',
							file)
					end
					--[[/minify-delete]]

					if token.text == 'reduce' then
						local op = token.children[2]
						if op.id == TOK.func_ref then
							override_tp = TYPESIG[op.text].out
						elseif op.id == TOK.op_bitwise then
							override_tp = TYPE_NUMBER
						elseif std.arrfind({ '+', '-', '/', '//', '%' }, op.text, 1) > 0 then
							override_tp = TYPE_NUMBER
						elseif std.arrfind({ '=', '<', '<=', '>', '>=', '!=', 'and', 'or', 'xor' }, op.text, 1) > 0 then
							override_tp = TYPE_BOOLEAN
						end
					end
				else
					parse_error(
						token.span,
						'COMPILER BUG: No signature definition for function `' .. token.text .. '`!',
						file
					)
				end

				if #token.children > 0 then
					local found_correct_types = false

					if signature.valid then
						--Check that type signature of the params match up with the list of accepted types.
						for g = 1, #signature.valid do
							local found_match = true
							for i = 1, #token.children do
								local tp = token.children[i].type
								if tp then
									local s = signature.valid[g]
									if not SIMILAR_TYPE(tp, s[(i - 1) % #s + 1]) then found_match = false end
								end
							end
							if found_match then
								found_correct_types = true
								break
							end
						end

						if not found_correct_types then
							local options, got_types = {}, {}

							for i = 1, #signature.valid do
								table.insert(options, std.join(signature.valid[i], ',', TYPE_TEXT))
							end

							for i = 1, #token.children do
								table.insert(got_types, TYPE_TEXT(token.children[i].type or TYPE_ANY))
							end

							local msg
							if BUILTIN_FUNCS[token.text] then
								msg = 'Function "' .. token.text .. '(' .. funcsig(token.text) .. ')"'
							else
								msg = 'Operator "' .. token.text .. '"'
							end
							parse_error(token.span,
								msg .. ' expected (' .. std.join(options, ' or ') .. ') but got (' ..
								std.join(got_types, ',') .. ')', file)
						end
					end

					if type(signature.out) == 'number' then
						--Return type matches that of the nth param
						token.type = token.children[signature.out].type
					else
						token.type = signature.out
					end
				else
					token.type = signature.out
				end

				if override_tp then token.type = override_tp end
			end,

			function(token, file)
				--Make sure that the argument passed to `reduce()` has all the correct types.
				if token.text ~= 'reduce' then return end

				local arg_tp, op = token.children[1].type, token.children[2]
				if not arg_tp then return end
				if op.id ~= TOK.func_ref then return end

				local subtype = GET_SUBTYPES(arg_tp)
				local fn_types = TYPESIG[op.text].valid

				local valid = false
				local invalid_arg_pos = 1
				for _, params in ipairs(fn_types) do
					valid = true
					for i, param_tp in ipairs(params) do
						if not SIMILAR_TYPE(subtype, param_tp) then
							valid = false
							invalid_arg_pos = i
							break
						end
					end
					if valid then break end
				end

				if not valid then
					local msg = 'Cannot `reduce(' .. TYPE_TEXT(arg_tp) .. ', ...)`'
					msg = msg .. ' with the function `' .. op.text .. '(' .. funcsig(op.text) .. ')`'
					msg = msg .. ' because parameter ' .. invalid_arg_pos .. ' of ' .. op.text
					msg = msg .. ' is incompatible with type `' .. TYPE_TEXT(subtype) .. '`.'
					parse_error(op.span, msg, file)
				end
			end,
		},

		[TOK.ternary] = {
			function(token)
				local type1, type2 = token.children[2].type, token.children[3].type
				if type1 and type2 then
					token.type = MERGE_TYPES(type1, type2)
				end
			end,
		},

		[TOK.list_comp] = {
			function(token, file)
				local it = token.children[3]
				if it.type and not SIMILAR_TYPE(it.type, TYPE_ITERABLE) then
					parse_error(
						it.span,
						'List comprehension expected an iterable of type (array|object) but got (' ..
						TYPE_TEXT(it.type) .. ').',
						file
					)
				end

				token.type = it.type or TYPE_ARRAY
			end,
		},

		[TOK.array_slice] = {
			require_args_op(TYPE_NUMBER),
			function(token, file)
				token.type = TYPE_ARRAY_NUMBER

				if #token.children == 1 and not token.unterminated then
					parse_error(
						token.children[1].span,
						'Unterminated slices are only allowed inside index operations, e.g. `var1[i::]`.',
						file
					)
				end
			end,
		},

		[TOK.object] = {
			function(token, file)
				local tp
				for _, child in ipairs(token.children) do
					local subchild = child.children[2]
					if subchild.type then
						tp = tp and MERGE_TYPES(tp, subchild.type) or subchild.type
					end
				end

				token.type = OBJECT_FROM_TYPE(tp or TYPE_ANY)
			end,
		},
	},
}
