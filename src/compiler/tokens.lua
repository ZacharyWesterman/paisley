local _tok_i = -1
---Dynamically generate a new token ID.
---@return integer
local function k()
	_tok_i = _tok_i + 1
	return _tok_i
end

---@enum TOK Possible token ids.
TOK = {
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
	--[[minify-delete]] kwd_import_file = k(), --[[/minify-delete]]

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
	return_stmt = k(),
	statement = k(),

	lit_array = k(), --This only gets created during constant folding
	lit_object = k(),
	object = k(),

	subroutine_label = k(),--This is only a temporary token to make subroutine construction unambiguous. It does not show up in a finalized AST.
	--[[minify-delete]] import_stmt = k(), --[[/minify-delete]]

	no_value = k(),
}

require "src.compiler.span"

---@class (exact) Token
---@field span Span The range of text this token spans.
---@field id TOK The token ID.
---@field private meta_id TOK? ONLY used during AST generation! The ID this token was coerced into.
---@field text string The text from the input file that this token represents.
---@field value any The literal value that was calculated for this token, if any. Used for constant folding.
---@field children Token[]? A list of child nodes.
---@field type string? The data type that was deduced for this token, if any.
---@field inside_object boolean? If defined and true, this token is inside an object declaration.
---@field ignore boolean? If true, optimize this token away. Only defined on subroutine and variable definitions.
---@field unterminated boolean? Whether this slice token is unterminated (e.g. var[1::]). Only defined on slices.
---@field is_referenced boolean? Whether this subroutine token is referenced. Only defined on subroutine and variable definitions.
---@field filename string? The name of the file that this token came from.
Token = {}

--[[minify-delete]]
SHOW_MULTIPLE_ERRORS = false
HIDE_ERRORS = false
--[[/minify-delete]]
ERRORED = false

---Print errors to the console.
---@param span Span
---@param msg string
---@param file string?
function parse_error(span, msg, file)
	if msg:sub(1, 12) == 'COMPILER BUG' then
		msg = msg .. '\nTHIS IS A BUG IN THE PAISLEY COMPILER, PLEASE REPORT IT!'
		--[[minify-delete]]
		msg = msg:gsub('\n', ' ')
		--[[/minify-delete]]
	end

	--[[minify-delete]]
	if not HIDE_ERRORS then
		if _G['LANGUAGE_SERVER'] then
			INFO.error(span, msg, file)
		else --[[/minify-delete]]
			if file ~= nil and file ~= '' then
				print(file..': '..span.from.line..', '..span.from.col..': '..msg)
			else
				print(span.from.line..', '..span.from.col..': '..msg)
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

--[[minify-delete]]
local function lsp_msg(span, msg, loglevel, file)
	if file == INFO.root_file or not _G['LANGUAGE_SERVER'] or not INFO.root_file then
		print(loglevel..','..(span.from.line-1)..','..span.from.col..','..(span.to.line-1)..','..span.to.col..'|'..msg)
	end
end

INFO = {
	hint      = function(span, msg, file) lsp_msg(span, msg, 'H', file) end,
	warning   = function(span, msg, file) lsp_msg(span, msg, 'W', file) end,
	info      = function(span, msg, file) lsp_msg(span, msg, 'I', file) end,
	error     = function(span, msg, file) lsp_msg(span, msg, 'E', file) end,
	dead_code = function(span, msg, file) lsp_msg(span, msg, 'D', file) end,
	root_file = nil,
}
--[[/minify-delete]]

function terminate()
	--[[minify-delete]] if _G['LANGUAGE_SERVER'] or _G['REPL'] then error() else --[[/minify-delete]]
	error('ERROR in user-supplied Paisley script.')
	--[[minify-delete]] end --[[/minify-delete]]
end

function token_text(token_id)
	for key, value in pairs(TOK) do
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

	if token.ignored ~= nil or token.is_referenced ~= nil then
		meta = meta .. ' ['
		if token.ignored then meta = meta..'#' else meta = meta..'-' end
		if token.is_referenced then meta = meta..'#' else meta = meta..'-' end
		meta = meta .. ']'
	end

	print((indent..'%2d:%2d: %13s = %s%s'):format(token.span.from.line, token.span.from.col, id, token.text:gsub('\n', '<nl>'):gsub('\x09','<nl>'), meta))
end

function print_tokens_recursive(root, indent)
	if indent == nil then indent = '' end
	print_token(root, indent)
	if root.children then
		for _, child in pairs(root.children) do
			print_tokens_recursive(child, indent..'  ')
		end
	end
end
--[[/minify-delete]]
