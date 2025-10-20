local token, last_token, file_name
local token_i = 0
local token_list = {}

local function ast_error(symbol, valid_tokens)
	local error_msg = 'Unexpected token.'
	local list = {}

	if type(symbol) == 'table' then symbol = symbol[1] end
	if not symbol then symbol = token end
	if not symbol then
		error_msg = 'Unexpected EOF.'
	elseif type(symbol) == 'table' then
		error_msg = 'Unexpected token <' .. token_text(symbol.id) .. '>.'
	elseif type(symbol) ~= 'function' then
		error_msg = 'Unexpected token <' .. token_text(symbol) .. '>.'
	end

	if valid_tokens then
		if type(valid_tokens) ~= 'table' then valid_tokens = { valid_tokens } end

		for i = 1, #valid_tokens do
			if type(valid_tokens[i]) == 'string' then
				table.insert(list, '`' .. valid_tokens[i] .. '`')
			else
				table.insert(list, '<' .. token_text(valid_tokens[i]) .. '>')
			end
		end
	end

	if #list > 0 then
		local last = table.remove(list)
		error_msg = error_msg .. ' Expected '
		if #list > 0 then
			error_msg = error_msg .. std.join(list, ', ') .. ' or '
		end
		error_msg = error_msg .. last .. '.'
	end

	parse_error((symbol or token or last_token).span, error_msg, file_name)
end

local function nextsym()
	last_token = token
	token_i = token_i + 1
	token = token_list[token_i]
end

local function accept(symbol)
	local ok, node
	if not token then return false, token end

	if type(symbol) == 'function' then
		ok, node = symbol(token.span)
	else
		ok, node = (token and token.id == symbol), token
		if ok then nextsym() end
	end

	return ok, node
end

local function expect(symbol, valid_tokens)
	local ok, node = accept(symbol)
	if not ok then
		ast_error(token.id, valid_tokens or { symbol })
	end
	return ok, node
end

local function skip(symbol)
	while accept(symbol) do
		--
	end
end

local function any_of(symbol_list, valid_symbol_list, required)
	local ok, node = false, token
	for i = 1, #symbol_list do
		ok, node = accept(symbol_list[i])
		if ok then break end
	end
	if required and not ok then
		ast_error(token, valid_symbol_list)
	end
	return ok, node
end

local function zero_or_more(symbol)
	local list = {}
	local ok, node = accept(symbol)
	while ok do
		table.insert(list, node)
		ok, node = accept(symbol)
	end
	return true, list
end

local function one_or_more(symbol)
	local ok, list = zero_or_more(symbol)
	if #list == 0 then ok = false end
	return ok, list
end

local function expect_list(symbols, valid_symbols, skip_symbol)
	local list = {}
	for i = 1, #symbols do
		if skip_symbol then skip(skip_symbol) end

		local symbol = symbols[i]
		local valid = valid_symbols[i]
		if type(symbol) ~= 'table' then symbol = { symbol } end
		if type(valid) ~= 'table' then valid = { valid } end

		local ok, node = any_of(symbol, valid, true)
		if not ok then
			return false, list
		end

		table.insert(list, node)
	end
	return true, list
end


return {
	set_token_list = function(tokens, filename)
		token_list = tokens
		file_name = filename
	end,
	out = function(ok)
		return ok, token
	end,
	t = function() return token end,

	ast_error = ast_error,

	nextsym = nextsym,
	accept = accept,
	expect = expect,
	skip = skip,
	any_of = any_of,
	zero_or_more = zero_or_more,
	one_or_more = one_or_more,
	expect_list = expect_list,
}
