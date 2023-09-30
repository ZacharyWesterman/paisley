_tok_i = -1
function k()
	_tok_i = _tok_i + 1
	return _tok_i
end

tok = {
	text = k(),

	kwd_for = k(),
	kwd_while = k(),
	kwd_in = k(),
	kwd_do = k(),
	kwd_if = k(),
	kwd_then = k(),
	kwd_elif = k(),
	kwd_else = k(),
	kwd_end = k(),
	kwd_continue = k(),
	kwd_break = k(),
	kwd_delete = k(),
	kwd_do = k(),
	kwd_goto = k(),
	kwd_gosub = k(),
	kwd_return = k(),
	kwd_let = k(),
	kwd_stop = k(),

	expr_open = k(),
	expr_close = k(),
	variable = k(),
	lit_number = k(),

	op_plus = k(),
	op_minus = k(),
	op_times = k(),
	op_idiv = k(),
	op_div = k(),
	op_mod = k(),
	op_slice = k(),
	op_count = k(),
	op_length = k(),
	op_not = k(),
	op_and = k(),
	op_or = k(),
	op_xor = k(),
	op_in = k(),
	op_exists = k(),
	op_like = k(),
	op_ge = k(),
	op_gt = k(),
	op_le = k(),
	op_lt = k(),
	op_eq = k(),
	op_ne = k(),
	op_comma = k(),
	op_concat = k(),

	paren_open = k(),
	paren_close = k(),

	lit_true = k(),
	lit_false = k(),
	lit_null = k(),

	string_open = k(),
	string_close = k(),

	label = k(),
	command_open = k(),
	command_close = k(),

	line_ending = k(),
	op_assign = k(),

	index_open = k(),
	index_close = k(),

	--Below this point are composite or meta tokens that don't exist during initial lexing phase, only get created as part of AST gen

	value = k(), --any value in an expression: number, string, literal, or variable
	add = k(), -- value + value, value - value
	multiply = k(), -- multiplication or division
	boolean = k(),
	index = k(),
	array_concat = k(),
	array_slice = k(),
	comparison = k(),
	negate = k(),
	string = k(),

	expression = k(),
}

function parse_error(line, col, msg, file)
	if file ~= nil then
		error(file..': '..line..', '..col..': '..msg)
	else
		error(line..', '..col..': '..msg)
	end
end

function token_text(token_id)
	local key
	local value
	for key, value in pairs(tok) do
		if token_id == value then
			return key
		end
	end
	return string.format('%d', token_id)
end

function print_token(token, indent)
	if indent == nil then indent = '' end

	local id = token_text(token.id)
	if token.meta_id ~= nil then id = token_text(token.id)..'*' end

	print((indent..'%2d:%2d: %13s = %s'):format(token.line, token.col, id, token.text:gsub('[\n\x0b]', '<newline>')))
end

function print_tokens_recursive(root, indent)
	local child
	local _
	if indent == nil then indent = '' end
	print_token(root, indent)
	if root.children then
		for _, child in pairs(root.children) do
			print_tokens_recursive(child, indent..'  ')
		end
	end
end