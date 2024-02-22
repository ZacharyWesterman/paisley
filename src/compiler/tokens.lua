_tok_i = -1
function k()
	_tok_i = _tok_i + 1
	return _tok_i
end

tok = {
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
	kwd_subroutine = k(),
	kwd_gosub = k(),
	kwd_return = k(),
	kwd_let = k(),
	kwd_initial = k(),
	kwd_stop = k(),
	kwd_if_expr = k(),
	kwd_else_expr = k(),
	kwd_for_expr = k(),

	expr_open = k(),
	expr_close = k(),
	variable = k(),
	var_assign = k(),
	lit_number = k(),

	text = k(),

	op_plus = k(),
	op_minus = k(),
	op_times = k(),
	op_idiv = k(),
	op_div = k(),
	op_mod = k(),
	op_exponent = k(),
	op_slice = k(),
	op_count = k(),
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
	op_exclamation = k(),
	op_dot = k(),
	op_arrow = k(),

	paren_open = k(),
	paren_close = k(),

	lit_boolean = k(),
	lit_null = k(),

	index_open = k(),
	index_close = k(),

	--Below this point are composite or meta tokens that don't exist during initial lexing phase, only get created as part of AST gen

	value = k(), --any value in an expression: number, string, literal, or variable
	add = k(), -- value + value, value - value
	multiply = k(), -- multiplication or division
	exponent = k(),
	boolean = k(),
	index = k(),
	array_concat = k(),
	array_slice = k(),
	key_value_pair = k(),
	comparison = k(),
	negate = k(),
	string = k(),
	parentheses = k(),
	func_call = k(),
	concat = k(),
	length = k(),
	ternary = k(),
	list_comp = k(),

	string_open = k(),
	string_close = k(),
	lambda = k(),
	lambda_ref = k(),

	expression = k(),
	inline_command = k(),
	command_close = k(),
	command = k(),
	command_open = k(),

	line_ending = k(),
	program = k(),
	op_assign = k(),

	if_stmt = k(),
	else_stmt = k(),
	elif_stmt = k(),
	while_stmt = k(),
	for_stmt = k(),
	delete_stmt = k(),
	subroutine = k(),
	gosub_stmt = k(),
	let_stmt = k(),
	break_stmt = k(),
	continue_stmt = k(),
	statement = k(),

	lit_array = k(), --This only gets created during constant folding
	lit_object = k(),
	object = k(),
}

--[[minify-delete]]
SHOW_MULTIPLE_ERRORS = false
HIDE_ERRORS = false
--[[/minify-delete]]
ERRORED = false
function parse_error(line, col, msg, file)
	if msg:sub(1, 12) == 'COMPILER BUG' then
		msg = msg .. '\nTHIS IS A BUG IN THE PAISLEY COMPILER, PLEASE REPORT IT!'
		--[[minify-delete]]
		msg = msg:gsub('\n', ' ')
		--[[/minify-delete]]
	end

	--[[minify-delete]]
	if not HIDE_ERRORS then
		if LANGUAGE_SERVER then
			print((line-1)..','..col..','..(line-1)..','..col..'|'..msg)
		else --[[/minify-delete]]
			if file ~= nil and file ~= '' then
				print(file..': '..line..', '..col..': '..msg)
			else
				print(line..', '..col..': '..msg)
			end
		--[[minify-delete]]
		end
	end
	--[[/minify-delete]]

	ERRORED = true
	--[[minify-delete]] if not SHOW_MULTIPLE_ERRORS then --[[/minify-delete]]
	terminate()
	--[[minify-delete]] end --[[/minify-delete]]
end

function terminate()
	error('ERROR in user-supplied Paisley script.')
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

--[[minify-delete]]
function print_token(token, indent)
	if indent == nil then indent = '' end

	local id = token_text(token.id)
	local meta = ''

	if DEBUG_EXTRA then
		if token.meta_id ~= nil then
			id = token_text(token.id)..'*'
			meta = '    (meta='..token_text(token.meta_id)..')'
		end
	else
		if token.value ~= nil then
			meta = '    (='..std.debug_str(token.value)..')'
			if token.type ~= nil then
				meta = '    ('..token.type..'='..std.debug_str(token.value)..')'
			end
		elseif token.type ~= nil then
			meta = '    ('..token.type..')'
		end
	end

	print((indent..'%2d:%2d: %13s = %s%s'):format(token.line, token.col, id, token.text:gsub('\n', '<nl>'):gsub('\x09','<nl>'), meta))
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
--[[/minify-delete]]
