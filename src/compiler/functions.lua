local words = require 'src.shared.words'
local std = require 'src.shared.stdlib'
local json = require 'src.shared.json'

local fold_operations = {
	['=='] = function(a, b) return a == b end,
	['<'] = function(a, b) return a < b end,
	['<='] = function(a, b) return a <= b end,
	['>'] = function(a, b) return a > b end,
	['>='] = function(a, b) return a >= b end,
	['!='] = function(a, b) return a ~= b end,
	['+'] = function(a, b) return std.num(a) + std.num(b) end,
	['-'] = function(a, b) return std.num(a) - std.num(b) end,
	['*'] = function(a, b) return std.num(a) * std.num(b) end,
	['/'] = function(a, b) return std.num(a) / std.num(b) end,
	['//'] = function(a, b) return math.floor(std.num(a) / std.num(b)) end,
	['%'] = function(a, b) return std.num(a) % std.num(b) end,
	['and'] = function(a, b) return std.bool(a) and std.bool(b) end,
	['or'] = function(a, b) return std.bool(a) or std.bool(b) end,
	['xor'] = function(a, b) return (std.bool(a) or std.bool(b)) and not (std.bool(a) and std.bool(b)) end,
}

return {
	--Internal function call codes. Not usable in syntax as actual functions.
	jump = 1,
	jumpifnil = 2,
	jumpiffalse = 3,
	explode = 4,
	implode = 5,
	superimplode = 6,
	add = 7,
	sub = 8,
	mul = 9,
	div = 10,
	rem = 11,
	length = 12,
	arrayindex = 13,
	arrayslice = 14,
	concat = 15,
	booland = 16,
	boolor = 17,
	boolxor = 18,
	inarray = 19,
	strlike = 20,
	equal = 21,
	notequal = 22,
	greater = 23,
	greaterequal = 24,
	less = 25,
	lessequal = 26,
	boolnot = 27,
	varexists = 28,

	--[[BELOW: Built-in functions, usable in language.]]

	irandom = {
		index = 29,
		param_ct = {2},
		valid = {{'number'}},
		out = 'number',
		fold = false, --cannot fold this function as it's not deterministic
	},

	frandom = {
		index = 30,
		param_ct = {2},
		valid = {{'number'}},
		out = 'number',
		fold = false, --cannot fold this function as it's not deterministic
	},

	worddiff = {
		index = 31,
		param_ct = {2},
		valid = {{'string'}},
		out = 'number',
		fold = function(a, b) return words.lev(a, b) end,
	},

	dist = {
		index = 32,
		param_ct = {2},
		valid = {{'number'}, {'array'}},
		out = 'number',
		validate = function(a, b)
			if type(a) ~= type(b) then
				return 'Function "dist(a,b)" expected (number, number) or (array, array) but got ('..std.type(a)..', '..std.type(b)..')'
			end

			if type(a) == 'number' then
				a = {a}
				b = {b}
			end

			if #a ~= #b then
				return 'Function "dist(a,b)" expected arrays of equal length, got lengths '..#a..' and '..#b
			end
		end,
		fold = function(a, b)
			if type(a) == 'number' then
				return math.abs(b - a)
			end

			local total, i = 0
			for i = 1, #a do
				local p = a[i] - b[i]
				total = total + p*p
			end
			return math.sqrt(total)
		end,
	},

	sin = {
		index = 33,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.sin(x) end,
	},

	cos = {
		index = 34,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.cos(x) end,
	},

	tan = {
		index = 35,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.tan(x) end,
	},

	asin = {
		index = 36,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.asin(x) end,
	},

	acos = {
		index = 37,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.acos(x) end,
	},

	atan = {
		index = 38,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.atan(x) end,
	},

	atan2 = {
		index = 39,
		param_ct = {2},
		valid = {{'number'}},
		out = 'number',
		fold = function(x, y) return math.atan2(x, y) end,
	},

	sqrt = {
		index = 40,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.sqrt(x) end,
	},

	sum = {
		index = 41,
		param_ct = {'1+'},
		valid = {{'number'}, {'array'}},
		out = 'number',
		fold = function(values)
			local total, i = 0, nil
			for i = 1, #values do
				if type(values[i]) == 'table' then
					local k
					for k = 1, #values[i] do
						total = total + values[i][k]
					end
				else
					total = total + values[i]
				end
			end
			return total
		end,
	},

	mult = {
		index = 42,
		param_ct = {'1+'},
		valid = {{'number'}, {'array'}},
		out = 'number',
		fold = function(values)
			local total, i = 1, nil
			for i = 1, #values do
				if type(values[i]) == 'table' then
					local k
					for k = 1, #values[i] do
						total = total * values[i][k]
					end
				else
					total = total * values[i]
				end
			end
			return total
		end,
	},

	pow = {
		index = 43,
		param_ct = {2},
		valid = {{'number'}},
		out = 'number',
		fold = function(a, b) return math.pow(a, b) end,
	},

	min = {
		index = 44,
		param_ct = {'1+'},
		valid = {{'number'}, {'array'}},
		out = 'number',
		fold = function(values)
			local least, i = values[1], nil
			for i = 2, #values do least = math.min(least, values[i]) end
			return least
		end,
	},

	max = {
		index = 45,
		param_ct = {'1+'},
		valid = {{'number', 'array'}},
		out = 'number',
		fold = function(values)
			local most, i = values[1], nil
			for i = 2, #values do most = math.max(most, values[i]) end
			return most
		end,
	},

	split = {
		index = 46,
		param_ct = {2},
		valid = {{'string', 'string'}},
		out = 'array',
		fold = function(a, b) return std.split(a, b) end,
	},

	join = {
		index = 47,
		param_ct = {2},
		valid = {{'array', 'string'}},
		out = 'string',
		fold = function(a, b) return std.join(a, b) end,
	},

	type = {
		index = 48,
		param_ct = {1},
		valid = {{'any'}},
		out = 'string',
		fold = function(a) return std.type(a) end,
	},

	bool = {
		index = 49,
		param_ct = {1},
		valid = {{'any'}},
		out = 'boolean',
		fold = function(data) return std.bool(data) end,
	},

	num = {
		index = 50,
		param_ct = {1},
		valid = {{'any'}},
		out = 'number',
		fold = function(data) return std.num(data) end,
	},

	str = {
		index = 51,
		param_ct = {1},
		valid = {{'any'}},
		out = 'string',
		fold = function(data) return std.str(data) end,
	},

	array = {
		index = 52,
		param_ct = {'0+'},
		valid = {{'any'}},
		out = 'array',
		fold = function(values) return values end, --Interesting short-cut due to compiler quirks!
	},

	floor = {
		index = 53,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.floor(x) end,
	},

	ceil = {
		index = 54,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.ceil(x) end,
	},

	round = {
		index = 55,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.round(x) end,
	},

	abs = {
		index = 56,
		param_ct = {1},
		valid = {{'number'}},
		out = 'number',
		fold = function(x) return math.abs(x) end,
	},

	append = {
		index = 57,
		param_ct = {2},
		valid = {{'array', 'any'}},
		out = 'array',
		fold = function(a, b)
			table.insert(a, b)
			return a
		end,
	},

	index = {
		index = 58,
		param_ct = {2},
		valid = {{'array', 'any'}, {'string', 'any'}},
		out = 'number',
		fold = function(a, b)
			if type(a) == 'table' then
				return std.arrfind(a, b)
			else
				return std.strfind(a, std.str(b))
			end
		end,
	},

	lower = {
		index = 59,
		param_ct = {1},
		valid = {{'string'}},
		out = 'string',
		fold = function(a) return a:lower() end,
	},

	upper = {
		index = 60,
		param_ct = {1},
		valid = {{'string'}},
		out = 'string',
		fold = function(a) return a:lower() end,
	},

	camel = {
		index = 61,
		param_ct = {1},
		valid = {{'string'}},
		out = 'string',
		fold = function(a)
			if #a == 0 then return '' end
			return a:sub(1,1):upper() .. a:sub(2,#a):lower()
		end,
	},

	replace = {
		index = 62,
		param_ct = {3},
		valid = {{'string'}},
		out = 'string',
		fold = function(subject, search, replace)
			--Not really memory efficient, but good enough.
			return std.join(std.split(subject, search), replace)
		end,
	},

	json_encode = {
		index = 63,
		param_ct = {1},
		valid = {{'any'}},
		out = 'string',
		validate = function(data)
			local result, err = json.stringify(data, nil, true)
			if err then return err end
		end,
		fold = function(data)
			return json.stringify(data, nil, true)
		end,
	},

	json_decode = {
		index = 64,
		param_ct = {1},
		valid = {{'string'}},
		out = 'any',
		validate = function(data)
			local result, err = json.parse(data, true)
			if err then return err end
		end,
		fold = function(data)
			return json.parse(data, true)
		end,
	},

	json_valid = {
		index = 65,
		param_ct = {1},
		valid = {{'string'}},
		out = 'boolean',
		fold = function(data) return json.verify(data) end,
	},

	b64_encode = {
		index = 66,
		param_ct = {1},
		valid = {{'string'}},
		out = 'string',
		fold = function(text) return std.b64_encode(text) end,
	},

	b64_decode = {
		index = 67,
		param_ct = {1},
		valid = {{'string'}},
		out = 'string',
		fold = function(text) return std.b64_decode(text) end,
	},

	lpad = {
		index = 68,
		param_ct = {3},
		valid = {{'string', 'string', 'number'}},
		out = 'string',
		fold = function(text, character, width)
			local c = character:sub(1,1)
			return c:rep(width-#text) .. text
		end,
	},

	rpad = {
		index = 69,
		param_ct = {3},
		valid = {{'string', 'string', 'number'}},
		out = 'string',
		fold = function(text, character, width)
			local c = character:sub(1,1)
			return text .. c:rep(width-#text)
		end,
	},

	hex = {
		index = 70,
		param_ct = {1},
		valid = {{'number'}},
		out = 'string',
		fold = function(value) return string.format('%x', value) end,
	},

	filter = {
		index = 71,
		param_ct = {2},
		valid = {{'string'}},
		out = 'string',
		fold = function(text, pattern) return std.filter(text, pattern) end,
	},

	isnumber = {
		index = 72,
		param_ct = {1},
		valid = {{'string'}},
		out = 'boolean',
		fold = function(text) return std.isnumber(text) end,
	},

	clocktime = {
		index = 73,
		param_ct = {1},
		valid = {{'number'}},
		out = 'array',
		fold = function(value)
			return {
				math.floor(value / 3600),
				math.floor(value / 60) % 60,
				math.floor(value) % 60,
				math.floor(value * 1000) % 1000,
			}
		end,
	},

	reverse = {
		index = 74,
		param_ct = {1},
		valid = {{'array'}},
		out = 'array',
		fold = function(value)
			local result, i = {}
			for i = #value, 1, -1 do
				table.insert(result, value[i])
			end
			return result
		end,
	},

	sort = {
		index = 75,
		param_ct = {1},
		valid = {{'array'}},
		out = 'array',
		fold = function(value)
			table.sort(value)
			return value
		end,
	},

	bytes = {
		index = 76,
		param_ct = {2},
		valid = {{'number'}},
		out = 'array',
		fold = function(array1, array2)
			local i
			for i = 1, #array2 do
				table.insert(array1, array2[i])
			end
			return array1
		end,
	},

	frombytes = {
		index = 77,
		param_ct = {1},
		valid = {{'array'}},
		out = 'number',
		fold = function(values)
			local result, i = 0
			for i = #values, 1, -1 do
				result = result * 256 + values[i]
			end
			return result
		end,
	},

	merge = {
		index = 78,
		param_ct = {2},
		valid = {{'array', 'array'}},
		out = 'array',
		fold = function(array1, array2)
			local i
			for i = 1, #array2 do
				table.insert(array1, array2[i])
			end
			return array1
		end,
	},

	update = {
		index = 79,
		param_ct = {3},
		valid = {{'array', 'number', 'any'}},
		out = 'array',
		fold = function(array, index, value)
			array[index] = value
			return array
		end,
	},

	insert = {
		index = 80,
		param_ct = {3},
		valid = {{'array', 'number', 'any'}},
		out = 'array',
		fold = function(array, index, value)
			table.insert(array, index, value)
			return array
		end,
	},

	delete = {
		index = 81,
		param_ct = {2},
		valid = {{'array', 'number'}},
		out = 'array',
		fold = function(array, index)
			table.remove(array, index)
			return array
		end,
	},

	lerp = {
		index = 82,
		param_ct = {3},
		valid = {{'number'}},
		out = 'number',
		fold = function(x, a, b) return a + x * (b - a) end,
	},

	reduce = {
		--No index since this gets converted to a combo of min() and max() at compile time.
		index = false,
		param_ct = {2},
		valid = {{'array', 'any'}},
		out = 'any',
		validate = function(values, operator)
			if not fold_operations[operator] then
				return 'COMPILER BUG: No constant folding rule for reduce(array, '..operator..')!'
			end
		end,
		fold = function(values, operator)
			if #values == 0 then return nil end

			local result, i = values[1]
			local oper = fold_operations[operator]
			for i = 2, #values do
				result = oper(result, values[i])
			end
			return result
		end,
	},

	clamp = {
		--No index since this gets converted to a combo of min() and max() at compile time.
		index = false,
		param_ct = {3},
		valid = {{'number'}},
		out = 'number',
		fold = function(value, min, max) return math.min(max, math.max(min, value)) end,
	},
}