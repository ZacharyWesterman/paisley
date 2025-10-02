return {
	clamp = function(token)
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
	end,

	int = function(token)
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
	end,

	all = function(token)
		--Convert "all(x)" into "reduce(x, and)"
		token.text = 'reduce'
		table.insert(token.children, {
			id = TOK.op_and,
			span = token.span,
			text = 'and',
		})
	end,

	any = function(token)
		--Convert "any(x)" into "reduce(x, or)"
		token.text = 'reduce'
		table.insert(token.children, {
			id = TOK.op_or,
			span = token.span,
			text = 'or',
		})
	end,

	shuffle = function(token)
		--Convert "shuffle(x)" into "random_elements(x, MAX_INT)"
		token.text = 'random_elements'
		table.insert(token.children, {
			id = TOK.lit_number,
			span = token.span,
			type = TYPE_NUMBER,
			value = std.MAX_ARRAY_LEN,
			text = tostring(std.MAX_ARRAY_LEN),
		})
	end,

	cot = function(token)
		--Convert "cot(x)" into "1 / tan(x)"
		token.text = '/'
		token.id = TOK.multiply
		token.children = {
			{
				id = TOK.lit_number,
				span = token.span,
				type = TYPE_NUMBER,
				value = 1,
				text = '1',
			},
			{
				id = TOK.func_call,
				span = token.span,
				text = 'tan',
				children = token.children,
			},
		}
	end,

	acot = function(token)
		--Convert "acot(x)" into "atan(1 / x)"
		token.text = 'atan'
		token.id = TOK.func_call
		token.children = {
			{
				id = TOK.multiply,
				span = token.span,
				text = '/',
				children = {
					{
						id = TOK.lit_number,
						span = token.span,
						type = TYPE_NUMBER,
						value = 1,
						text = '1',
					},
					token.children[1],
				},
			},
		}
	end,

	asec = function(token)
		--Convert "sec(x)" into "1 / cos(x)"
		token.text = '/'
		token.id = TOK.multiply
		token.children = {
			{
				id = TOK.lit_number,
				span = token.span,
				value = 1,
			},
			{
				id = TOK.func_call,
				span = token.span,
				text = 'cos',
				children = token.children,
			},
		}
	end,

	csc = function(token)
		--Convert "csc(x)" into "1 / sin(x)"
		token.text = '/'
		token.id = TOK.multiply
		token.children = {
			{
				id = TOK.lit_number,
				span = token.span,
				type = TYPE_NUMBER,
				value = 1,
				text = '1',
			},
			{
				id = TOK.func_call,
				span = token.span,
				text = 'sin',
				children = token.children,
			},
		}
	end,

	acsc = function(token)
		--Convert "acsc(x)" into "asin(1 / x)"
		token.text = 'asin'
		token.id = TOK.func_call
		token.children = {
			{
				id = TOK.multiply,
				span = token.span,
				text = '/',
				children = {
					{
						id = TOK.lit_number,
						span = token.span,
						type = TYPE_NUMBER,
						value = 1,
						text = '1',
					},
					token.children[1],
				},
			},
		}
	end,
}
