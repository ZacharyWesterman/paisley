
local tok = require 'src.compiler.tokens'
local std = require 'src.shared.stdlib'

local function parse_error(line, col, msg, file)
	if msg:sub(1, 12) == 'COMPILER BUG' then
		msg = msg .. '\nTHIS IS A BUG IN THE PAISLEY COMPILER, PLEASE REPORT IT!'
	end

	if file ~= nil and file ~= '' then
		print(file..': '..line..', '..col..': '..msg)
	else
		print(line..', '..col..': '..msg)
	end
	error('ERROR in user-supplied Paisley script.')
end

local function token_text(token_id)
	local key
	local value
	for key, value in pairs(tok) do
		if token_id == value then
			return key
		end
	end
	return string.format('%d', token_id)
end

local function print_token(token, indent)
	if indent == nil then indent = '' end

	local id = token_text(token.id)
	local meta = ''

	-- if COMPILER_DEBUG then
		if token.meta_id ~= nil then
			id = token_text(token.id)..'*'
			meta = '    (meta='..token_text(token.meta_id)..')'
		end
	-- else
		-- if token.value ~= nil then
		-- 	meta = '    (='..std.debug_str(token.value)..')'
		-- 	if token.type ~= nil then
		-- 		meta = '    ('..token.type..'='..std.debug_str(token.value)..')'
		-- 	end
		-- elseif token.type ~= nil then
		-- 	meta = '    ('..token.type..')'
		-- end
	-- end

	print((indent..'%2d:%2d: %13s = %s%s'):format(token.line, token.col, id, token.text:gsub('\n', '<nl>'):gsub('\x09','<nl>'), meta))
end

local function print_tokens_recursive(root, indent)
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

return {
	parse_error = parse_error,
	token_text = token_text,
	print_token = print_token,
	print_tokens_recursive = print_tokens_recursive,
}