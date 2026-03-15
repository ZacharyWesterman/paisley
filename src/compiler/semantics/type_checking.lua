local current_sub
local labels = {}
--[[minify-delete]]
local in_cmd_eval = false
--[[/minify-delete]]
local funcsig
local function set_var(var, datatype, value) end
local function get_var(name) end
local function push_var(var, datatype) end

--Temporary variables (e.g. list comprehension) that don't actually affect
--the value/type of global variables, even with the same name.
local temp_vars = {}

local type_changed = false
local function set_type(token, new_type)
	if not type_changed then
		type_changed = token.type == nil and new_type ~= nil
	end
	token.type = new_type
end

local nodes_identical = require 'src.compiler.nodes_identical'


local function command(token, file)
	local ch = token.children[1]

	--function eval is different
	if ch.id == TOK.call_stmt then
		if not token.type then
			local lbl = ch.children[1]
			if labels[lbl.text] then set_type(token, labels[lbl.text].type) end
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
			set_type(token, ALLOWED_COMMANDS[ch.value])
		else
			set_type(token, BUILTIN_COMMANDS[ch.value])
		end
	end

	if token.id == TOK.inline_command then set_type(token, token.children[1].type) end
end

local function type_from_value(token)
	if token.value ~= nil or token.id == TOK.lit_null then
		set_type(token, SIGNATURE(std.deep_type(token.value)))
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
	set = function(new_labels, new_funcsig, set_var_func, get_var_func, push_var_func)
		labels = new_labels
		current_sub = nil
		in_cmd_eval = false
		funcsig = new_funcsig
		type_changed = true
		set_var = set_var_func
		get_var = get_var_func
		push_var = push_var_func
		temp_vars = {}
	end,

	needs_iter = function()
		return type_changed
	end,

	ready_new_iter = function()
		type_changed = false
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

		[TOK.list_comp] = {
			function(token)
				local var = token.children[2]
				temp_vars[var.text] = var

				local expr_type = token.children[3].type
				if not expr_type then return end
				expr_type = GET_SUBTYPES(expr_type)
				if not expr_type then return end

				--Set the type of the temporary variable.
				set_type(var, expr_type)
			end,
		},

		[TOK.for_stmt] = {
			function(token)
				local var, expr = token.children[1], token.children[2]
				if not expr.type then return end

				local tp
				if SIMILAR_TYPE(expr.type, TYPE_OBJECT) then
					tp = MERGE_TYPES(tp, TYPE_STRING)
				end
				if SIMILAR_TYPE(expr.type, TYPE_ARRAY) then
					tp = MERGE_TYPES(tp, GET_SUBTYPES(expr.type))
				end
				if not tp then tp = expr.type end

				if tp then
					set_var(var, tp)
					set_type(var, tp)
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
					set_type(token, TYPE_NULL)
				end
			end
		},

		[TOK.index] = {
			function(token, file)
				local c1, c2 = token.children[1], token.children[2]

				if current_sub and c1.id == TOK.variable and c1.text == '@' and type(c2.value) == 'number' then
					--Deduce the type of function arguments, if annotated.
					local func = labels[current_sub]
					if func and func.tags and func.tags.params then
						local param = func.tags.params[c2.value]
						if param and param.type then
							set_type(token, param.type)
							return
						end
					end
				end

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

				if not t1 or not t2 then return end

				if SIMILAR_TYPE(t1, TYPE_OBJECT) then
					set_type(token, GET_SUBTYPES(t1))
					return
				end

				if not SIMILAR_TYPE(t2, TYPE_INDEXER) then
					print(TYPE_TEXT(t1), TYPE_TEXT(TYPE_INDEXER))
					parse_error(token.children[1].span,
						'Cannot index with a value of type `' ..
						TYPE_TEXT(t2) .. '`. Must be `array[number]` or `number`', file)
					return
				end

				if EXACT_TYPE(t1, TYPE_STRING) then
					set_type(token, TYPE_STRING)
				elseif EXACT_TYPE(t2, TYPE_ANY) then
					--If index is "any", result is either the same type as t1, or the subtype of t1
					set_type(token, MERGE_TYPES(t1, GET_SUBTYPES(t1)))
				elseif SIMILAR_TYPE(t2, TYPE_ARRAY) then
					if HAS_SUBTYPES(t1) then
						set_type(token, t1)
					else
						set_type(token, ARRAY_FROM_TYPE(t1))
					end
				elseif HAS_SUBTYPES(t1) then
					set_type(token, GET_SUBTYPES(t1))
				else
					--We don't know what type of array this is, so result of non-const array index has to be "any"
					set_type(token, TYPE_ANY)
				end
			end,
		},

		[TOK.string_open] = {
			function(token)
				set_type(token, TYPE_STRING)
			end,
		},

		[TOK.add] = {
			require_args_op(TYPE_NUMBER),
			function(token) set_type(token, TYPE_NUMBER) end,
		},

		[TOK.negate] = {
			require_args_op(TYPE_NUMBER),
			function(token) set_type(token, TYPE_NUMBER) end,
		},

		[TOK.multiply] = {
			require_args_op(TYPE_NUMBER),
			function(token) set_type(token, TYPE_NUMBER) end,
		},

		[TOK.exponent] = {
			require_args_op(TYPE_NUMBER),
			function(token) set_type(token, TYPE_NUMBER) end,
		},

		[TOK.bitwise] = {
			require_args_op(TYPE_NUMBER),
			function(token) set_type(token, TYPE_NUMBER) end,
		},

		[TOK.boolean] = {
			function(token) set_type(token, TYPE_BOOLEAN) end,
		},

		[TOK.comparison] = {
			function(token) set_type(token, TYPE_BOOLEAN) end,

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

				set_type(token, ARRAY_FROM_TYPE(tp or TYPE_ANY))
			end,
		},

		[TOK.concat] = {
			function(token) set_type(token, TYPE_STRING) end,
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

				set_type(token, TYPE_NUMBER)
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
						elseif std.arrfind({ '*', '+', '-', '/', '//', '%' }, op.text, 1) > 0 then
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
						--Return type matches that of the nth argument,
						--Or if more strict, the expected type(s) of the param.
						local index = signature.out
						local arg_type = token.children[index].type
						local param_type = signature.valid[1][index]
						for i = 2, #signature.valid do
							param_type = MERGE_TYPES(param_type, signature.valid[i][index])
						end
						local tp = TYPE_IS_SUBSET(arg_type, param_type) and param_type or arg_type
						set_type(token, tp)
					else
						set_type(token, signature.out)
					end
				else
					set_type(token, signature.out)
				end

				if override_tp then set_type(token, override_tp) end
			end,

			function(token, file)
				--Make sure that the argument passed to `reduce()` has all the correct types.
				if token.text ~= 'reduce' then return end

				local arg_tp, op = token.children[1].type, token.children[2]
				if not arg_tp then return end

				local fn_types
				if op.id ~= TOK.func_ref then
					if std.arrfind({ '=', '<', '<=', '>', '>=', '!=', 'and', 'or', 'xor' }, op.text, 1) > 0 then
						return --Comparison can accept a list containing any arbitrary types.
					end
					fn_types = { { TYPE_NUMBER, TYPE_NUMBER } }
				else
					fn_types = TYPESIG[op.text].valid
				end

				local subtype = GET_SUBTYPES(arg_tp)

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
						.. ' with the ' .. (op.id == TOK.func_ref and 'function' or 'operator')
						.. ' `' .. op.text .. (op.id == TOK.func_ref and ('(' .. funcsig(op.text) .. ')`') or '`')
						.. ' because ' ..
						(op.id == TOK.func_ref and ('parameter ' .. invalid_arg_pos .. ' of ' .. op.text) or 'it')
						.. ' is incompatible with type `' .. TYPE_TEXT(subtype) .. '`.'
					parse_error(op.span, msg, file)
				end
			end,
		},

		[TOK.ternary] = {
			function(token)
				local condition, type1, type2 = token.children[1], token.children[2].type, token.children[3].type
				if not type1 or not type2 then return end

				if condition.id == TOK.comparison and condition.text == '!=' then
					local lhs, rhs = condition.children[1], condition.children[2]
					local arg

					if lhs.value == false or lhs.id == TOK.lit_null or (lhs.type and TYPE_IS_SUBSET(lhs, TYPE_NULL)) then
						arg = rhs
					elseif rhs.value == false or rhs.id == TOK.lit_null or (rhs.type and TYPE_IS_SUBSET(rhs, TYPE_NULL)) then
						arg = lhs
					end

					if arg and nodes_identical(arg, token.children[2]) then
						set_type(token, MERGE_TYPES(NON_NULL(type1), type2))
						return
					end
				elseif condition.id == TOK.lit_null or (condition.type and TYPE_IS_SUBSET(condition.type, TYPE_NULL)) then
					set_type(token, MERGE_TYPES(NON_NULL(type1), type2))
					return
				elseif condition.value == false then
					set_type(token, type2)
					return
				end

				set_type(token, MERGE_TYPES(type1, type2))
			end,
		},

		[TOK.list_comp] = {
			function(token, file)
				local var, it = token.children[2], token.children[3]
				temp_vars[var.text] = nil

				if it.type and not SIMILAR_TYPE(it.type, TYPE_ITERABLE) then
					parse_error(
						it.span,
						'List comprehension expected an iterable of type (array|object) but got (' ..
						TYPE_TEXT(it.type) .. ').',
						file
					)
					return
				end

				local iter_type = token.children[1].type or TYPE_ANY
				set_type(token, ARRAY_FROM_TYPE(iter_type))
			end,
		},

		[TOK.array_slice] = {
			require_args_op(TYPE_NUMBER),
			function(token, file)
				set_type(token, TYPE_ARRAY_NUMBER)

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
			function(token)
				local tp
				for _, child in ipairs(token.children) do
					local subchild = child.children[2]
					if subchild.type then
						tp = tp and MERGE_TYPES(tp, subchild.type) or subchild.type
					end
				end

				set_type(token, OBJECT_FROM_TYPE(tp or TYPE_ANY))
			end,
		},

		[TOK.variable] = {
			--Set var types
			function(token)
				if token.text == '@' then
					set_type(token, current_sub and TYPE_ARRAY or TYPE_ARRAY_STRING)
				elseif token.text == '$' then
					set_type(token, TYPE_ARRAY_STRING)
				elseif token.text == '_VARS' then
					set_type(token, TYPE_OBJECT)
				elseif token.text == '_VERSION' then
					set_type(token, TYPE_STRING)
				elseif token.text == '_ENV' then
					set_type(token, TYPE_ENV)
				else
					local var_decl = temp_vars[token.text] or get_var(token.text)
					if var_decl then
						token.type = var_decl.type
					end
				end
			end,
		},

		[TOK.let_stmt] = {
			--Set expected type from annotations, and spit out a warning
			--if the actual type is not compatible with the annotation.
			function(token, file)
				--Index-assignment is different!
				if token.children[3] then return end

				local tp_list = token.tags and token.tags.type or {}
				local var = token.children[1]
				local var1_tp = token.children[2] and token.children[2].type
				local vars_tp = TYPE_NULL

				if #var.children > 0 and SIMILAR_TYPE(var1_tp, TYPE_ARRAY) then
					var1_tp = MERGE_TYPES(GET_SUBTYPES(var1_tp), TYPE_NULL)
					vars_tp = var1_tp
				end

				local tp_asgn = {
					{ node = var, tp = tp_list[1] or var1_tp },
				}
				for i, node in ipairs(var.children) do
					table.insert(tp_asgn, {
						node = node, tp = tp_list[i + 1] or vars_tp,
					})
				end

				for _, asgn in ipairs(tp_asgn) do
					if asgn.tp then
						set_var(asgn.node, asgn.tp)
						asgn.node.type = asgn.tp
					end
				end
			end,
		},

		[TOK.try_stmt] = {
			function(token)
				if token.children[3] then
					set_var(token.children[3], TYPE_OBJECT)
					token.children[3].type = TYPE_OBJECT
				end
			end
		},
	},
}
