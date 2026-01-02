local FUNCSIG = require "src.compiler.semantics.signature"

local loop_depth = 0

local function break_continue(token, file)
	local loop_out = token.children[1].value
	if loop_out > loop_depth then
		local phrase, plural, amt = 'break out', '', 'only ' .. loop_depth
		if token.id == TOK.continue_stmt then phrase = 'skip iteration' end
		if loop_out ~= 1 then plural = 's' end
		if loop_depth == 0 then amt = 'none' end
		parse_error(token.span,
			'Unable to ' .. phrase .. ' of ' .. loop_out ..
			' loop' .. plural .. ', ' .. amt .. ' found at this scope', file)
	end
end

local function loop_enter(token, file)
	loop_depth = loop_depth + 1
end

local function loop_exit(token, file)
	loop_depth = loop_depth - 1
end

local function cleanup_parens(token, file)
	if #token.children ~= 1 then return end

	local child = token.children[1]
	for _, key in ipairs({ 'value', 'id', 'text', 'span', 'type' }) do
		token[key] = child[key]
	end
	token.children = child.children
end

local labels = {}

return {
	set = function(_labels)
		labels = _labels
	end,

	enter = {

		[TOK.func_call] = {
			--Validate function calls
			function(token, file)
				if token.text:sub(1, 1) == '\\' then return end

				local func = BUILTIN_FUNCS[token.text]

				--Function doesn't exist
				if func == nil then
					local msg = 'Unknown function "' .. token.text .. '"'
					local guess = closest_word(token.text:lower(), BUILTIN_FUNCS, 4)

					if guess ~= nil then
						msg = msg .. ' (did you mean "' .. guess .. '(' .. FUNCSIG(guess) .. ')"?)'
					end
					parse_error(token.span, msg, file)
					return
				end

				--Check if function has the right number of params
				local param_ct = #token.children

				if func ~= param_ct then
					local plural = ''
					if func ~= 1 then plural = 's' end
					local verb = 'was'
					if param_ct ~= 1 then verb = 'were' end

					if func < 0 then
						--"-1" means any non-zero num of params, any other negative (-N) means "min 1, max N"

						if func == -1 then
							if param_ct == 0 then
								parse_error(token.span,
									'Function "' ..
									token.text ..
									'(' ..
									FUNCSIG(token.text) .. ')" expects at least 1 parameter, but ' ..
									param_ct .. ' ' .. verb .. ' given', file)
							end
						elseif param_ct > -func or param_ct < 1 then
							local plural = ''
							if func < -1 then plural = 's' end
							parse_error(token.span,
								'Function "' ..
								token.text ..
								'(' ..
								FUNCSIG(token.text) ..
								')" expects 1 to ' .. (-func) .. ' parameter' .. plural ..
								', but ' .. param_ct .. ' ' .. verb .. ' given', file)
						end
					else
						parse_error(token.span,
							'Function "' ..
							token.text ..
							'(' ..
							FUNCSIG(token.text) ..
							')" expects ' ..
							func .. ' parameter' .. plural .. ', but ' .. param_ct .. ' ' .. verb .. ' given',
							file)
					end
				end

				--For reduce() function, make sure that its second parameter is an operator/func_name/sub_name.
				if token.text == 'reduce' then
					local ch = token.children[2]

					local binary_ops = {
						[TOK.op_plus] = true,
						[TOK.op_minus] = true,
						[TOK.op_times] = true,
						[TOK.op_idiv] = true,
						[TOK.op_div] = true,
						[TOK.op_mod] = true,
						[TOK.op_and] = true,
						[TOK.op_or] = true,
						[TOK.op_xor] = true,
						[TOK.op_ge] = true,
						[TOK.op_gt] = true,
						[TOK.op_le] = true,
						[TOK.op_lt] = true,
						[TOK.op_eq] = true,
						[TOK.op_ne] = true,
						[TOK.op_bitwise] = true,
					}

					if binary_ops[ch.id] then
						--It's a binary operator, all valid.
					elseif ch.id == TOK.variable and ch.text:sub(1, 1) == '\\' then
						--Assume a subroutine name was given,
						--make sure it's a valid name.
						local sub_name = ch.text:sub(2)
						if not labels[sub_name] then
							local msg = 'Subroutine `' .. sub_name .. '` not declared anywhere'
							local guess = closest_word(sub_name, labels, 4)
							if guess ~= nil and guess ~= '' then
								msg = msg .. ' (did you mean "' .. guess .. '"?)'
							end
							parse_error(ch.span, msg, file)
							return
						end

						ch.id = TOK.sub_ref
						ch.text = sub_name
						--Make sure to mark that this subroutine is in use,
						--so it does not get pruned later on.
						labels[sub_name].is_referenced = true
					elseif ch.id == TOK.variable then
						local ch_func = BUILTIN_FUNCS[ch.text]

						--Assume a built-in function name was given,
						--make sure it's a valid name, and it can accept exactly 2 arguments.
						if ch_func == nil then
							local msg = 'Unknown function "' .. ch.text .. '"'
							local guess = closest_word(ch.text:lower(), BUILTIN_FUNCS, 4)

							if guess ~= nil then
								msg = msg .. ' (did you mean "' .. guess .. '(' .. FUNCSIG(guess) .. ')"?)'
							end
							parse_error(ch.span, msg, file)
						elseif ch.text == 'reduce' then
							local msg = 'The function `' .. ch.text .. '(' ..
								FUNCSIG(ch.text) .. ')` is not compatible with `reduce()`.'
							parse_error(ch.span, msg, file)
						elseif ch_func >= 0 and ch_func < 2 then
							local msg = 'The function `' .. ch.text .. '(' ..
								FUNCSIG(ch.text) .. ')` is not compatible with `reduce()`.'
							msg = msg .. ' 2 arguments are required, but ' .. ch.text .. ' takes ' .. ch_func .. '.'
							parse_error(ch.span, msg, file)
						else
							--Make sure the output of the function is compatible with the first parameter.
							local signature = TYPESIG[ch.text]
							local valid = false

							for _, arg in ipairs(signature.valid) do
								---@diagnostic disable-next-line
								if SIMILAR_TYPE(signature.out, arg[1]) then
									valid = true
									break
								end
							end

							if not valid then
								local msg = 'The function `' .. ch.text .. '(' .. FUNCSIG(ch.text)
								---@diagnostic disable-next-line
								msg = msg .. ') -> ' .. TYPE_TEXT(signature.out)
								msg = msg .. '` is not compatible with `reduce()`.'
								msg = msg ..
									' The function\'s return value cannot be passed as its first argument due to incompatible types.'
								parse_error(ch.span, msg, file)
							end
						end

						ch.id = TOK.func_ref
					else
						parse_error(ch.span,
							'The second parameter of "reduce(a,b)" must be a binary operator (e.g. + or *), or the name of a function or subroutine',
							file)
					end
				else
					for i = 1, #token.children do
						local child = token.children[i]
						if child.id >= TOK.op_plus and child.id <= TOK.op_arrow then
							parse_error(child.span,
								'Function "' ..
								token.text ..
								'(' ..
								FUNCSIG(token.text) ..
								')" cannot take an operator as a parameter (found "' .. child.text .. '")',
								file)
						end
					end
				end
			end,
		},

		[TOK.break_stmt] = { break_continue },
		[TOK.continue_stmt] = { break_continue },

		[TOK.while_stmt] = { loop_enter },
		[TOK.for_stmt] = { loop_enter },
		[TOK.kv_for_stmt] = { loop_enter },

		[TOK.index] = {
			--Convert _ENV accesses to a function call
			function(token, file)
				if token.children[1].text == '_ENV' then
					token.id = TOK.func_call
					token.text = 'env_get'
					token.type = nil
					token.value = nil
					token.children = { token.children[2] }
				end
			end,
		},

		[TOK.variable] = {
			--Don't allow reading the entirety of _ENV, as it may be very large
			--(and it's a little expensive to copy all the values)
			function(token, file)
				if token.text == '_ENV' then
					parse_error(token.span,
						'Reading the entirety of _ENV is not allowed. Try accessing individual keys instead.', file)
				end
			end,
		}
	},

	exit = {
		[TOK.while_stmt] = { loop_exit },
		[TOK.for_stmt] = { loop_exit },
		[TOK.kv_for_stmt] = { loop_exit },
		[TOK.expression] = { cleanup_parens },
		[TOK.parentheses] = { cleanup_parens },
	},

	finally = function()
		return FUNCSIG
	end,
}
