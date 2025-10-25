local token, last_token, file_name
local token_i = 0
local token_list = {}

---@brief Generate an error message indicating invalid syntax.
---@param symbol function|Token|integer The token or token id to generate the error message for.
---@param valid_tokens any Either a single, or a list of, expected token ids/text.
---@return nil
local function ast_error(symbol, valid_tokens)
	ERROR = true

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
				table.insert(list, '<' .. token_text(valid_tokens[i]):gsub('_', ' ') .. '>')
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

	parse_error((token or last_token).span, error_msg, file_name)
end

---@brief Get the next symbol from the token list
---@return nil
local function nextsym()
	last_token = token
	token_i = token_i + 1
	token = token_list[token_i]
end

---@brief Accept a symbol if it shows up, but don't error if it's not there.
---@param symbol function|integer The symbol id or parsing function.
---@return boolean ok True if the symbol was found, false otherwise.
---@return Token node The generated AST node if the symbol was found, or the current token if not.
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

---@brief Require a symbol to show up next, and error if it's not there.
---@param symbol function|integer The symbol id or parsing function.
---@param valid_tokens any? Either a single, or a list of, expected token ids/text.
---@return boolean ok True if the symbol was found, false otherwise.
---@return Token node The generated AST node if the symbol was found, or the current token if not.
local function expect(symbol, valid_tokens)
	local ok, node = accept(symbol)
	if not ok then
		ast_error(token and token.id, valid_tokens or { symbol })
	end
	return ok, node
end

---@brief Skip any number of occurrences of the given symbol
---@param symbol function|integer The symbol id or parsing function.
---@return nil
local function skip(symbol)
	while accept(symbol) do end
end

---@brief Accept any of a list of symbols.
---@param symbol_list (function|integer)[] A list of symbol ids or parsing functions.
---@param valid_symbol_list (integer|string)[] A list, each element containing either a single, or a list of, expected token ids/text.
---@param required boolean? Whether to error if none of the symbols were found.
---@return boolean ok True if one of the symbols was found, false otherwise.
---@return Token node The generated AST node if one of the symbols was found, or the current token if not.
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

---@brief Accept any number of a given symbol, skipping if none are present.
---@param symbol function|integer The symbol id or parsing function.
---@return boolean ok true.
---@return Token[] list All the found symbols.
local function zero_or_more(symbol)
	local list = {}
	local ok, node = accept(symbol)
	while ok do
		table.insert(list, node)
		ok, node = accept(symbol)
	end
	return true, list
end

---@brief Accept at least one of a given symbol.
---@param symbol function|integer The symbol id or parsing function.
---@return boolean ok True if at least one of the symbol was found, false otherwise.
---@return Token[] list All the found symbols.
local function one_or_more(symbol)
	local ok, list = zero_or_more(symbol)
	if #list == 0 then ok = false end
	return ok, list
end

---@brief Accept only zero or one of a given symbol, and error if any more are found.
---@param symbol function|integer The symbol id or parsing function.
---@param valid_tokens any Either a single, or a list of, expected token ids/text.
---@return boolean ok True if at one of the symbol was found, false otherwise.
---@return Token node The generated AST node if the symbol was found, or the current token if not.
local function zero_or_one(symbol, valid_tokens)
	local ok, node = accept(symbol)
	if not ok then return ok, node end

	if accept(symbol) then
		if type(valid_tokens) ~= 'table' then valid_tokens = { valid_tokens } end

		local list = {}
		for i = 1, #valid_tokens do
			if type(valid_tokens[i]) == 'string' then
				table.insert(list, '`' .. valid_tokens[i] .. '`')
			else
				table.insert(list, '<' .. token_text(valid_tokens[i]):gsub('_', ' ') .. '>')
			end
		end

		local error_msg = 'Expected only one of '
		local last = table.remove(list)
		if #list > 0 then
			error_msg = error_msg .. std.join(list, ', ') .. ' or '
		end
		error_msg = error_msg .. last .. ', but multiple were found.'
		parse_error(node.span, error_msg, file_name)

		return false, token
	end

	return true, node
end

---Require a list of symbols to appear in an exact order.
---
---Each symbol in the list may have several options, e.g.
---```
---{
---  a,
---  {b, c},
---  d
---}
---```
---would match symbol "a", then *either* symbols "b" or "c",
---and then symbol "d".
---
---@param symbols (function|integer|table)[] A list of symbol ids or parsing functions (or lists thereof).
---@param valid_symbols (integer|string|table)[] A list, each element containing either a single, or a list of, expected token ids/text.
---@param skip_symbol (integer|function)? The symbol to ignore, if any.
---@return boolean ok True if all the symbols were found, false otherwise.
---@return Token[] list All the found symbols.
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

---Look ahead some number of tokens.
---@param count integer? The number of tokens to look ahead. Defaults to 1.
---@return integer[] id_list A list of token ids that are yet to be consumed.
local function peek(count)
	if not count then count = 1 end

	local list = {}
	for i = token_i, token_i + count - 1 do
		local t = token_list[i]
		if t then table.insert(list, t.id) end
	end

	return list
end


return {
	set_token_list = function(tokens, filename)
		token_list = tokens
		file_name = filename
		last_token = nil
		token_i = 0
	end,
	out = function(ok)
		return ok, token
	end,
	t = function() return token end,
	filename = function() return file_name end,

	ast_error = ast_error,

	nextsym = nextsym,
	accept = accept,
	expect = expect,
	skip = skip,
	any_of = any_of,
	zero_or_more = zero_or_more,
	one_or_more = one_or_more,
	expect_list = expect_list,
	zero_or_one = zero_or_one,

	peek = peek,
}
