local tok = require 'src.compiler.tokens'

return {
	--Treat all literals the same.
	[tok.value] = {
		match = {{tok.lit_number}, {tok.lit_boolean}, {tok.lit_null}, {tok.negate}, {tok.string}, {tok.parentheses}, {tok.variable}},
		text = 'value',
	},

	--Multiplication
	[tok.multiply] = {
		match = {{tok.value, tok.op_times, tok.value}, {tok.value}},
		text = 'mult',
	},

	-- --Addition (lower precedence than multiplication)
	-- [tok.add] = {
	-- 	match = {{tok.multiply, tok.op_plus, tok.multiply}, {tok.multiply}},
	-- 	text = 'add',
	-- },

	[tok.expression] = {
		match = {{tok.expr_open, tok.multiply, tok.expr_close}},
		text = 'expr',
	}
}
