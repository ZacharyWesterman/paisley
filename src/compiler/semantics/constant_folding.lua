local function is_const(token)
	return token.value ~= nil or token.id == TOK.lit_null
end

local function if_const(func)
	return function(token, file)
		local values = { token, file }
		for _, child in ipairs(token.children) do
			if not is_const(child) then return end
			table.insert(values, child.value)
		end

		---@diagnostic disable-next-line
		local u = table.unpack or unpack
		token.value = func(u(values))
		token.children = {}
		token.id = ({
			boolean = TOK.lit_boolean,
			number = TOK.lit_number,
			string = TOK.string_open,
			array = TOK.lit_array,
			object = TOK.lit_object,
		})[std.type(token.value)]
	end
end

local function copy_token(from, to)
	for key, val in pairs(from) do
		to[key] = val
	end
end

local string_concat = if_const(
	function(token, file)
		local result = token.value or ''
		for _, child in ipairs(token.children) do
			result = result .. std.str(child.value)
		end
		return result
	end
)

local func_operations = require 'src.compiler.functions.fold'

local function get_var(name) end

return {
	set = function(new_get_var)
		get_var = new_get_var
	end,

	enter = {},
	exit = {
		[TOK.add] = {
			if_const(
				function(token, file, lhs, rhs)
					return (token.text == '+') and (lhs + rhs) or (lhs - rhs)
				end
			),
		},

		[TOK.negate] = {
			if_const(
				function(token, file, val)
					return -val
				end
			),
		},

		[TOK.multiply] = {
			if_const(
				function(token, file, lhs, rhs)
					if token.text ~= '*' and rhs == 0 then
						parse_error(
							token.span,
							'Division by zero',
							file
						)
						return 1 --Just spit out some result, doesn't matter what since we errored.
					end

					return ({
						['*'] = function(a, b) return a * b end,
						['/'] = function(a, b) return a / b end,
						['//'] = function(a, b) return math.floor(a / b) end,
						['%'] = function(a, b) return a % b end,
					})[token.text](lhs, rhs)
				end
			),
		},

		[TOK.exponent] = {
			if_const(
				function(token, file, lhs, rhs)
					local result = lhs ^ rhs

					if result == 0 / 0 or result == 1 / 0 or result == -1 / 0 then
						parse_error(
							token.span,
							'Result of `' .. lhs .. '^' .. rhs .. '` is not a number.',
							file
						)
					end

					return result
				end
			),
		},

		[TOK.boolean] = {
			if_const(
				function(token, file, lhs, rhs)
					return ({
						['and'] = function(a, b) return a and b end,
						['or'] = function(a, b) return a or b end,
						['xor'] = function(a, b) return (a or b) and not (a and b) end,
						['not'] = function(a) return not a end,
					})[token.text](std.bool(lhs), std.bool(rhs))
				end
			),
		},

		[TOK.comparison] = {
			if_const(
				function(token, file, lhs, rhs)
					return std.compare(lhs, rhs, ({
						['='] = function(a, b) return a == b end,
						['!='] = function(a, b) return a ~= b end,
						['>'] = function(a, b) return a > b end,
						['<'] = function(a, b) return a < b end,
						['>='] = function(a, b) return a >= b end,
						['<='] = function(a, b) return a <= b end,
						['like'] = function(a, b) return a:match(b) ~= nil end,
						['in'] = function(a, b)
							return (type(b) == 'string' and std.strfind or std.arrfind)(b, a, 1) ~= 0
						end,
					})[token.text])
				end
			),
		},

		[TOK.bitwise] = {
			if_const(
				function(token, file, lhs, rhs)
					return std.bitwise[token.text](lhs, rhs)
				end
			),
		},

		[TOK.ternary] = {
			function(token)
				local cond = token.children[1]
				if not is_const(cond) then return end

				--If condition is constant, ternaries can be folded
				local new_token = token.children[std.bool(cond.value) and 2 or 3]
				copy_token(new_token, token)
			end,
		},

		[TOK.list_comp] = {
			function(token)
				--If the expression has the form "i for i in EXPR (no condition)" then can optimize the whole list comprehension away.
				local kids = token.children
				if kids[1].id == TOK.variable and kids[1].text == kids[2].text and not kids[4] then
					copy_token(kids[3], token)
				end
			end,
		},

		[TOK.object] = {
			function(token)
				local result = std.object()

				for _, child in ipairs(token.children) do
					local key, val = child.children[1], child.children[2]
					if not is_const(key) or not is_const(val) then return end

					result[std.str(key.value)] = val.value
				end

				token.id = TOK.lit_object
				token.children = {}
				token.value = result
			end,
		},

		[TOK.array_slice] = {
			function(token, file)
				local kids = token.children

				--Can't expand unterminated slice
				if #kids < 2 then return end

				--Can only expand slice if it has a constant range.
				if not is_const(kids[1]) or not is_const(kids[2]) then return end

				local start, stop = kids[1].value, kids[2].value

				if (stop - start) >= std.MAX_ARRAY_LEN then
					local msg = 'Attempt to create an array of ' ..
						(stop - start + 1) .. ' elements (max is ' .. std.MAX_ARRAY_LEN .. '). Array truncated.'
					parse_warning(token.span, msg, file)

					stop = std.MAX_ARRAY_LEN + start - 1
				end

				--For the sake of output bytecode size, don't fold if the array slice is too large!
				if (stop - start) > 20 then return end

				local result = std.array()
				for i = start, stop do table.insert(result, i) end

				token.id = TOK.lit_array
				token.value = result
				token.children = {}
				token.reduce_array_concat = true
			end,
		},

		[TOK.array_concat] = {
			if_const(
				function(token)
					local result = std.array()
					for _, child in ipairs(token.children) do
						--If a slice operator is nested directly in array concat, merge the arrays.
						--E.g. `1,3:5,7` would result in `1,3,4,5,7`
						if child.reduce_array_concat then
							for _, subval in ipairs(child.value) do
								table.insert(result, subval)
							end
						else
							table.insert(result, child.value)
						end
					end
					return result
				end
			),
		},

		[TOK.concat] = { string_concat, },
		[TOK.string_open] = { string_concat, },

		[TOK.length] = {
			if_const(
				function(token, file, val)
					return #val
				end
			)
		},

		[TOK.func_call] = {
			function(token, file)
				--Handle any built-in functions that are NOT `reduce()`
				--Reduce is handled in a separate function.
				if token.text == 'reduce' then return end

				--Make sure all args are constant
				local args = std.array()
				for _, child in ipairs(token.children) do
					if not is_const(child) then return end
					table.insert(args, child.value)
				end

				local fn = func_operations[token.text]
				if fn then
					--Fold any *deterministic* built-in functions

					local param_ct = BUILTIN_FUNCS[token.text]
					local result
					if param_ct < 0 then
						result = fn(args, token, file)
					elseif param_ct == 0 then
						result = fn(token, file)
					elseif #args == 0 then
						result = fn(nil, token, file)
					else
						---@diagnostic disable-next-line
						local u = table.unpack or unpack
						table.insert(args, token)
						table.insert(args, file)
						result = fn(u(args))
					end

					token.value = result
					token.id = ({
						boolean = TOK.lit_boolean,
						number = TOK.lit_number,
						string = TOK.string_open,
						array = TOK.lit_array,
						object = TOK.lit_object,
					})[std.type(result)]
					token.children = {}
					return
				end

				fn = math[token.text]
				if fn then
					--Fold any deterministic functions that are in the lua `math` stdlib.

					local c1, c2 = token.children[1], token.children[2]
					local val1, val2 = fn(c1.value, c2 and c2.value)

					--math.modf returns two values, all others return only one.
					token.id = val2 and TOK.lit_array or TOK.lit_number
					token.value = val2 and { val1, val2 } or val1
					token.children = {}
					return
				end
			end,

			function(token, file)
				--Special handling for the `reduce()` function.
				--Reduce is handled in a separate function.
				if token.text ~= 'reduce' then return end

				local arg, func = token.children[1], token.children[2]


				if func.id == TOK.sub_ref then
					--Can't fold if using a user-defined function to reduce the values.
					return
				end

				--Make sure argument is constant
				if not is_const(arg) then return end

				if #arg.value == 0 then
					parse_warning(arg.span, 'Reducing an empty array will result in a value of `null`.', file)
				end

				local operator = func.text
				local reduce_fn = (func.id == TOK.op_bitwise) and std.bitwise[operator] or ({
					['='] = function(a, b) return std.equal(a, b) end,
					['!='] = function(a, b) return not std.equal(a, b) end,
					['<'] = function(a, b) return std.compare(a, b, function(c, d) return c < d end) end,
					['>'] = function(a, b) return std.compare(a, b, function(c, d) return c > d end) end,
					['<='] = function(a, b) return std.compare(a, b, function(c, d) return c <= d end) end,
					['>='] = function(a, b) return std.compare(a, b, function(c, d) return c >= d end) end,
					['+'] = function(a, b) return std.num(a) + std.num(b) end,
					['-'] = function(a, b) return std.num(a) - std.num(b) end,
					['*'] = function(a, b) return std.num(a) * std.num(b) end,
					['/'] = function(a, b)
						if b == 0 then
							parse_error(arg.span, 'Reduction involves division by zero.', file)
						end
						return std.num(a) / std.num(b)
					end,
					['//'] = function(a, b)
						if b == 0 then
							parse_error(arg.span, 'Reduction involves division by zero.', file)
						end
						return math.floor(std.num(a) / std.num(b))
					end,
					['%'] = function(a, b)
						if b == 0 then
							parse_error(arg.span, 'Reduction involves division by zero.', file)
						end
						return std.num(a) % std.num(b)
					end,
					['^'] = function(a, b) return std.num(a) ^ std.num(b) end,
					['and'] = function(a, b) return std.bool(a) and std.bool(b) end,
					['or'] = function(a, b) return std.bool(a) or std.bool(b) end,
					['xor'] = function(a, b)
						a, b = std.bool(a), std.bool(b)
						return (a or b) and not (a and b)
					end,
				})[operator]

				--Use built-in function instead.
				if func.id == TOK.func_ref then reduce_fn = func_operations[operator] end

				--If no deterministic built-in function, just skip.
				if not reduce_fn then return end

				local result = arg.value[1]
				for i = 2, #arg.value do
					local val = arg.value[i]
					if func.id == TOK.func_ref then
						local param_ct = BUILTIN_FUNCS[operator]
						result = (param_ct < 0) and reduce_fn({ result, val }, token, file) or
							reduce_fn(result, val, token, file)
					else
						result = reduce_fn(result, val)
					end
				end

				token.value = result
				token.id = ({
					boolean = TOK.lit_boolean,
					number = TOK.lit_number,
					string = TOK.string_open,
					array = TOK.lit_array,
					object = TOK.lit_object,
				})[std.type(result)]
				token.children = {}
			end
		},

		[TOK.index] = {
			if_const(
				function(token, file, lhs, rhs)
					if type(rhs) ~= 'table' then
						return lhs[rhs]
					end

					local result = std.array()
					for _, i in ipairs(rhs) do
						table.insert(result, lhs[i])
					end
					return result
				end
			),
		},

		[TOK.variable] = {
			function(token, file)
				local var = get_var(token.text)
				if not var then return end

				if var.multiple then
					--Don't optimize away if there are multiple (non-same) assignments of the variable
					token.value = nil
					return
				end

				local json = require 'src.shared.json'

				--This only applies if the variable is used inside the same scope as it was defined.
				if var.scope ~= token.scope then
					for decl, _ in pairs(var.decls) do
						decl.value = nil
						decl.multiple = true
					end
					var.multiple = true
					var.value = nil
					token.value = nil
					return
				end

				if Span:first(token.span, var.span) == var.span then
					--If the variable is assigned before it is used, use that value.
					token.value = var.value
				end
			end,
		},
	},
}
