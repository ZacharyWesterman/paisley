LUA = {
	---@class (exact) LUA.Token
	---@field text string
	---@field type string

	--- Tokenize a string of Lua code.
	--- @param text string
	--- @return LUA.Token[]
	tokenize = function(text)
		local tokens = {}

		local patterns = {
			{ '^%-%-.-\n',       'comment' }, -- Comments
			{ '^%-%-%[%[.-%]%]', 'comment' }, -- Multiline Comments
			{ '^%[%[.-%]%]',     'string' }, -- Multiline strings
			{ '^%".-%"',         'string' }, -- Strings
			{ '^\'.-\'',         'string' }, -- Strings
			{ '^[%w_]+',         'word' }, -- Words
			{ '^[%p]',           'symbol' }, -- Punctuation
			{ '^%s+',            'space' }, -- Whitespace
		}

		while #text > 0 do
			local found = false
			for _, pattern in ipairs(patterns) do
				local token = text:match(pattern[1])
				if token then
					table.insert(tokens, {
						text = token,
						type = pattern[2]
					})
					text = text:sub(#token + 1)
					found = true
					break
				end
			end

			if not found then
				error('ERROR When parsing Lua code: Unexpected character: `' .. text:sub(1, 1) .. '`.')
			end
		end

		return tokens
	end,

	--- Minify a string of Lua code.
	--- @param text string
	--- @return string
	minify = function(text)
		local tokens = LUA.tokenize(text)
		tokens = LUA.tokens.strip(tokens)
		return LUA.tokens.join(tokens)
	end,

	tokens = {
		--- Print a table of tokens.
		--- @param tokens LUA.Token[]
		--- @return nil
		print = function(tokens)
			for _, token in ipairs(tokens) do
				print(token.type, ' = ', token.text)
			end
		end,

		--- Remove whitespace and comments from a table of tokens.
		--- @param tokens LUA.Token[]
		--- @return LUA.Token[]
		strip = function(tokens)
			local stripped = {}
			for _, token in ipairs(tokens) do
				if token.type ~= 'space' and token.type ~= 'comment' then
					table.insert(stripped, token)
				end
			end
			return stripped
		end,

		--- Join a table of tokens into a string.
		--- @param tokens LUA.Token[]
		--- @return string
		join = function(tokens)
			local text = ''
			local prev = {
				type = 'space',
				text = '',
			}
			for _, token in ipairs(tokens) do
				if prev.type == 'word' and token.type == 'word' then
					text = text .. ' '
				end
				text = text .. token.text
				prev = token
			end
			return text
		end,
	},
}

-- require 'src.util.filesystem'
-- local fp = FS.open('src/meta/lua.lua', false)
-- LUA.tokens.print(LUA.tokens.strip(LUA.tokenize(fp:read('*a'))))
-- print(LUA.minify(fp:read('*a')))
