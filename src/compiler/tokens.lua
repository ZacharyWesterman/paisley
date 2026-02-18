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
	kwd_function = k(),
	kwd_call = k(),
	kwd_return = k(),
	kwd_let = k(),
	kwd_initial = k(),
	kwd_stop = k(),
	kwd_if_expr = k(),
	kwd_else_expr = k(),
	kwd_for_expr = k(),
	kwd_match = k(),
	kwd_cache = k(),
	kwd_using = k(),
	kwd_as = k(),
	--[[minify-delete]] kwd_import_file = k(), --[[/minify-delete]]
	kwd_try = k(),
	kwd_catch = k(),
	catch_expr = k(),

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
	op_divisible = k(),
	op_exponent = k(),
	op_slice = k(),
	op_concat = k(),
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
	op_bitwise = k(),
	op_question = k(),

	--[[minify-delete]]
	op_pipe_file_out = k(),
	op_pipe_file_in = k(),
	op_pipe_text_in = k(),
	op_pipe = k(),
	--[[/minify-delete]]

	paren_open = k(),
	paren_close = k(),

	lit_boolean = k(),
	lit_null = k(),

	index_open = k(),
	index_close = k(),

	--Below this point are composite or meta tokens that don't exist during initial lexing phase, only get created as part of AST gen

	value = k(), --any value in an expression: number, string, literal, or variable
	add = k(),   -- value + value, value - value
	multiply = k(), -- multiplication or division
	exponent = k(),
	boolean = k(),
	bitwise = k(),
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
	macro = k(),
	macro_ref = k(),

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
	kv_for_stmt = k(),
	delete_stmt = k(),
	function_def = k(),
	call_stmt = k(),
	let_stmt = k(),
	break_stmt = k(),
	continue_stmt = k(),
	return_stmt = k(),
	match_stmt = k(),
	uncache_stmt = k(),
	alias_stmt = k(),
	try_stmt = k(),
	scope_stmt = k(),
	statement = k(),

	lit_array = k(), --This only gets created during constant folding
	lit_object = k(),
	object = k(),

	--[[minify-delete]]
	import_stmt = k(),
	raw_sh_text = k(), --This only exists for the PC build. It basically just tells Paisley to not enclose that part of the command in quotes.
	--[[/minify-delete]]

	func_ref = k(),
	sub_ref = k(),

	no_value = k(),

	--Fake token IDs used for AST error reporting
	argument = k(),
	condition = k(),
	number = k(),
}

require "src.compiler.span"
local log = require 'src.log'

---@class (exact) Token
---@field span Span The range of text this token spans.
---@field id TOK The token ID.
---@field text string The text from the input file that this token represents.
---@field value any The literal value that was calculated for this token, if any. Used for constant folding.
---@field children Token[] A list of child nodes.
---@field type table? The data type that was deduced for this token, if any.
---@field inside_object boolean? If defined and true, this token is inside an object declaration.
---@field ignore boolean? If true, optimize this token away. Only defined on user-defined functions and variable definitions.
---@field unterminated boolean? Whether this slice token is unterminated (e.g. var[1::]). Only defined on slices.
---@field is_referenced boolean? Whether this function token is referenced. Only defined on user-defined functions and variable definitions.
---@field memoize boolean? If true, memoize (cache) calls to this user-defined function.
---@field filename string? The name of the file that this token came from.
---@field in_match boolean? If true, this is a boolean operator directly inside a "match" statement
---@field tags table? Defined on user-defined functions only, and contains parsed documentation comments.
Token = {}

--[[minify-delete]]
SHOW_MULTIPLE_ERRORS = false
HIDE_ERRORS = false
RAW_SH_TEXT_SENTINEL = string.char(255)
--[[/minify-delete]]
ERRORED = false

---Print errors to the console.
---@param span Span
---@param msg string
---@param file string?
---@diagnostic disable-next-line
function parse_error(span, msg, file)
	if msg:sub(1, 12) == 'COMPILER BUG' then
		msg = msg .. '\nTHIS IS A BUG IN THE PAISLEY COMPILER, PLEASE REPORT IT!'
		--[[minify-delete]]
		msg = msg:gsub('\n', ' ')
		--[[/minify-delete]]
	end

	--[[minify-delete]]
	if not HIDE_ERRORS then
		if LANGUAGE_SERVER then
			INFO.error(span, msg, file)
		elseif span == nil then
			print(msg)
		else
			--[[/minify-delete]]
			local line, col = span.from.line, span.from.col
			if col < 0 then col = 0 end
			if file ~= nil and file ~= '' then
				msg = (file .. ': ' .. line .. ', ' .. col .. ': ' .. msg)
			else
				msg = (line .. ', ' .. col .. ': ' .. msg)
			end

			log.error(msg)
			--[[minify-delete]]
		end
	end
	--[[/minify-delete]]

	ERRORED = true
	--[[minify-delete]]
	if not SHOW_MULTIPLE_ERRORS then --[[/minify-delete]]
		terminate()
		--[[minify-delete]]
	end --[[/minify-delete]]
end

---Print a warning to the console.
---@param span Span
---@param msg string
---@param file string?
---@diagnostic disable-next-line
function parse_warning(span, msg, file)
	--[[minify-delete]]
	if LANGUAGE_SERVER then
		INFO.warning(span, msg:gsub('\n', ' '), file)
	else
		---@diagnostic disable-next-line
		if WARNINGS_ARE_ERRORS then
			parse_error(span, msg, file)
			return
		end

		--[[/minify-delete]]
		msg = span.from.line .. ', ' .. span.from.col .. ': ' .. msg
		if file then msg = file .. ': ' .. msg end
		log.warn(msg)
		--[[minify-delete]]
	end
	--[[/minify-delete]]
end

---Print supplementary info to the console.
---@param span Span
---@param msg string
---@param file string?
---@diagnostic disable-next-line
function parse_info(span, msg, file)
	--[[minify-delete]]
	if LANGUAGE_SERVER then
		INFO.info(span, msg:gsub('\n', ' '), file)
	else
		--[[/minify-delete]]
		msg = span.from.line .. ', ' .. span.from.col .. ': ' .. msg
		if file then msg = file .. ': ' .. msg end
		log.info(msg)
		--[[minify-delete]]
	end
	--[[/minify-delete]]
end

--[[minify-delete]]
local function lsp_msg(span, msg, loglevel, file)
	if file == INFO.root_file or not LANGUAGE_SERVER or not INFO.root_file then
		msg = msg:gsub('\n', '\\n')
		local line, col = span.from.line, span.from.col
		if col < 0 then col = 0 end
		print(loglevel ..
			',' .. (line - 1) .. ',' .. col .. ',' .. (span.to.line - 1) .. ',' .. span.to.col .. '|' .. msg)
	end
end

INFO = {
	hint      = function(span, msg, file) lsp_msg(span, msg, 'H', file) end,
	warning   = function(span, msg, file) lsp_msg(span, msg, 'W', file) end,
	info      = function(span, msg, file) lsp_msg(span, msg, 'I', file) end,
	error     = function(span, msg, file) lsp_msg(span, msg, 'E', file) end,
	dead_code = function(span, msg, file) lsp_msg(span, 'dead_code', 'D', file) end,
	func_call = function(span, file) lsp_msg(span, 'func_call', 'D', file) end,
	constant  = function(span, file) lsp_msg(span, 'constant', 'D', file) end,
	root_file = nil,
}
--[[/minify-delete]]

function terminate()
	--[[minify-delete]]
	if true then
		os.exit(1)
	else --[[/minify-delete]]
		error('ERROR in user-supplied Paisley script.')
		--[[minify-delete]]
	end --[[/minify-delete]]
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
			id = token_text(token.id) .. '*'
			meta = '    (meta=' .. token_text(token.meta_id) .. ')'
		end
	else
		local tp = token.type
		if type(tp) == 'table' then tp = TYPE_TEXT(tp) else tp = std.debug_str(tp) end

		if token.value ~= nil then
			meta = '    (=' .. std.debug_str(token.value) .. ')'
			if token.type ~= nil then
				meta = '    (' .. tp .. '=' .. std.debug_str(token.value) .. ')'
			end
		elseif token.type ~= nil then
			meta = '    (' .. tp .. ')'
		end
	end

	if token.ignored ~= nil or token.is_referenced ~= nil then
		meta = meta .. ' ['
		if token.ignored then meta = meta .. '#' else meta = meta .. '-' end
		if token.is_referenced then meta = meta .. '#' else meta = meta .. '-' end
		meta = meta .. ']'
	end

	print((indent .. '%2d:%2d: %13s = %s%s'):format(token.span.from.line, token.span.from.col, id,
		(token.text or ''):gsub('\n', '<nl>'):gsub('\x09', '<nl>'), meta))
end

function print_tokens_recursive(root, indent)
	if indent == nil then indent = '' end
	print_token(root, indent)
	if root.children then
		for _, child in pairs(root.children) do
			print_tokens_recursive(child, indent .. '  ')
		end
	end
end

--[[/minify-delete]]

--Generate unique label ids (ones that can't clash with function names)
local _label_counter = 0
function LABEL_ID()
	_label_counter = _label_counter + 1
	return '?' .. _label_counter
end
