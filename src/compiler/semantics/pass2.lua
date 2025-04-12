local FUNCSIG = require "src.compiler.semantics.signature"

return {
	enter = {

		[TOK.func_call] = {
			--Move params of all function calls to be direct children
			--(this makes syntax like `a.func(b)` be the same as `func(a,b)`)
			function(token, file)
				if not token.children then
					token.children = {}
				elseif #token.children > 0 then
					local kids = {}
					for i = 1, #token.children do
						local child = token.children[i]
						if child.id == TOK.array_concat then
							for k = 1, #child.children do
								table.insert(kids, child.children[k])
							end
						else
							table.insert(kids, child)
						end
					end

					token.children = kids
				end
			end,

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

				--For reduce() function, make sure that its second parameter is an operator!
				if token.text == 'reduce' then
					local correct = false
					for i, k in pairs({ TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_idiv, TOK.op_div, TOK.op_mod, TOK.op_and, TOK.op_or, TOK.op_xor, TOK.op_ge, TOK.op_gt, TOK.op_le, TOK.op_lt, TOK.op_eq, TOK.op_ne }) do
						if token.children[2].id == k then
							correct = true
							break
						end
					end
					if not correct then
						parse_error(token.children[2].span,
							'The second parameter of "reduce(a,b)" must be a binary operator (e.g. + or *)', file)
					end
				elseif token.text == 'clamp' then
					--Convert "clamp" into max(min(upper_bound, x), lower_bound)
					---@type Token
					local node = {
						id = token.id,
						span = token.span,
						text = 'min',
						children = {
							token.children[1],
							token.children[3],
						},
						filename = token.filename,
					}
					token.text = 'max'
					token.children = { node, token.children[2] }
				elseif token.text == 'int' then
					--Convert "int" into floor(num(x))
					---@type Token
					local node = {
						id = token.id,
						span = token.span,
						text = 'num',
						children = token.children,
						filename = token.filename,
					}
					token.text = 'floor'
					token.children = { node }
				elseif token.text == 'shuffle' then
					--Convert "shuffle(x)" into "random_elements(x, MAX_INT)"
					token.text = 'random_elements'
					table.insert(token.children, {
						id = TOK.lit_number,
						span = token.span,
						type = TYPE_NUMBER,
						value = std.MAX_ARRAY_LEN,
						text = tostring(std.MAX_ARRAY_LEN),
					})
				elseif token.children then
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
	},

	exit = {
		[TOK.func_call] = {
			--Replace special function calls "\sub_name(arg1,arg2)" with "${gosub sub_name {arg1} {arg2}}"
			function(token, file)
				if token.text:sub(1, 1) ~= '\\' then return end

				--If function name begins with backslash, it's actually a gosub.
				---@type Token[]
				local kids = token.children or {}
				if kids[1] and kids[1].id == TOK.array_concat then kids = kids[1].children or {} end
				table.insert(kids, 1, {
					id = TOK.text,
					text = token.text:sub(2),
					span = token.span,
					type = TYPE_STRING,
					value = token.text:sub(2),
				})

				token.text = '${'
				token.id = TOK.inline_command
				token.children = { {
					id = TOK.gosub_stmt,
					text = 'gosub',
					span = token.span,
					children = kids,
				} }
			end,
		}
	},

	finally = function() end,
}
