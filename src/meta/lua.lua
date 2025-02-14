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
			{ '^%-%-%[%[.-%]%]', 'comment' }, -- Multiline Comments
			{ '^%-%-.-\n',       'comment' }, -- Comments
			{ '^%[%[.-%]%]',     'string' }, -- Multiline strings
			{ '^%".-%"',         'string' }, -- Strings
			{ '^\'.-\'',         'string' }, -- Strings
			{ '^[%w_]+',         'word' }, -- Words
			{ '^%(',             'lparen' }, -- Left Parentheses
			{ '^%)',             'rparen' }, -- Right Parentheses
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
	minify = function(text, standalone, remove_delete_blocks)
		local tokens = LUA.tokenize(text)

		if standalone then
			tokens = LUA.tokens.replace_requires(tokens)
		end

		if remove_delete_blocks then
			tokens = LUA.tokens.remove_delete_blocks(tokens)
		end

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

		--- Recursively parse require statements and split into a function call and the rest of the program.
		--- @param tokens LUA.Token[]
		--- @return LUA.Token[], LUA.Token[]
		extract_requires = function(tokens)
			local function match_types(tokens, i, group)
				for j = 1, #group do
					-- Ignore whitespace and comments
					while tokens[i].type == 'space' or tokens[i].type == 'comment' do
						i = i + 1
					end

					if tokens[i + j - 1].type ~= group[j] then
						return false
					end
				end
				return true
			end

			local function get_next_value(tokens, i, token_type)
				while tokens[i].type ~= token_type do
					i = i + 1
				end
				return tokens[i].text
			end

			local function get_next_index(tokens, i, token_type)
				while tokens[i].type ~= token_type do
					i = i + 1
				end
				return i
			end

			local require_groups = {}
			local rqid = 0
			local new_tokens = {}
			local i = 1
			while i <= #tokens do
				if tokens[i].text == 'require' and match_types(tokens, i + 1, { 'lparen', 'string', 'rparen' }) then
					local file = get_next_value(tokens, i, 'string'):sub(2, -2):gsub('%.', '/') .. '.lua'

					local fp = io.open(file)
					if not fp then
						error('ERROR: File not found: ' .. file)
					end
					if not require_groups[file] then
						rqid = rqid + 1
						require_groups[file] = {
							tokens = LUA.tokenize(fp:read('*a')),
							id = 'RQ' .. rqid,
						}
					end

					table.insert(new_tokens, { text = require_groups[file].id, type = 'word' })
					table.insert(new_tokens, { text = '(', type = 'lparen' })
					table.insert(new_tokens, { text = ')', type = 'rparen' })

					i = get_next_index(tokens, i, 'rparen')
					fp:close()
				elseif tokens[i].text == 'require' and match_types(tokens, i + 1, { 'string' }) then
					local file = get_next_value(tokens, i, 'string'):sub(2, -2):gsub('%.', '/') .. '.lua'
					local fp = io.open(file)
					if not fp then
						error('ERROR: File not found: ' .. file)
					end
					if not require_groups[file] then
						rqid = rqid + 1
						require_groups[file] = {
							tokens = LUA.tokenize(fp:read('*a')),
							id = 'RQ' .. rqid,
						}
					end

					table.insert(new_tokens, { text = require_groups[file].id, type = 'word' })
					table.insert(new_tokens, { text = '(', type = 'lparen' })
					table.insert(new_tokens, { text = ')', type = 'rparen' })

					i = get_next_index(tokens, i, 'string')
					fp:close()
				else
					table.insert(new_tokens, tokens[i])
				end
				i = i + 1
			end

			local requires = {}
			for _, group in pairs(require_groups) do
				local req_requires, req_tokens = LUA.tokens.extract_requires(group.tokens)
				for _, token in ipairs(req_requires) do
					table.insert(requires, token)
				end


				table.insert(requires, { text = 'function', type = 'word' })
				table.insert(requires, { text = group.id, type = 'word' })
				table.insert(requires, { text = '(', type = 'lparen' })
				table.insert(requires, { text = ')', type = 'rparen' })

				for _, token in ipairs(req_tokens) do
					table.insert(requires, token)
				end

				table.insert(requires, { text = 'end', type = 'word' })
			end

			return requires, new_tokens
		end,

		--- Replace all require calls with the appropriate file contents.
		--- @param tokens LUA.Token[]
		--- @return LUA.Token[]
		replace_requires = function(tokens)
			local requires, program = LUA.tokens.extract_requires(tokens)
			for _, token in ipairs(program) do
				table.insert(requires, token)
			end
			return requires
		end,

		--- Remove any blocks of code that are wrapped in `--[[minify-delete]]` ... `--[[/minify-delete]]` comments.
		--- @param tokens LUA.Token[]
		--- @return LUA.Token[]
		remove_delete_blocks = function(tokens)
			local new_tokens = {}
			local i = 1
			while i <= #tokens do
				if tokens[i].type == 'comment' and tokens[i].text == '--[[minify-delete]]' then
					while tokens[i].type ~= 'comment' or tokens[i].text ~= '--[[/minify-delete]]' do
						i = i + 1
					end
				else
					table.insert(new_tokens, tokens[i])
				end
				i = i + 1
			end
			return new_tokens
		end,
	},
}

local minified = LUA.minify([[
print('BEGIN')
require('test1')
require('test2')
print('END')
]], true, true)
-- tokens = LUA.tokens.replace_requires(tokens)
-- tokens = LUA.tokens.strip(tokens)
-- -- LUA.tokens.print(tokens)
-- print(LUA.tokens.join(tokens))
print(minified)
