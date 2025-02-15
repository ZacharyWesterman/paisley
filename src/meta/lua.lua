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
			{ '^%s+',            'space' }, -- Whitespace
			{ '^#!.-\n',         'comment' }, -- Shebang
			{ '^%-%-%[%[.-%]%]', 'comment' }, -- Multiline Comments
			{ '^%-%-.-\n',       'comment' }, -- Comments
			{ '^%[%[.-%]%]',     'string' }, -- Multiline strings
			{ '^%"',             'string' }, -- Strings
			{ '^\'',             'string' }, -- Strings
			{ '^[%w_]+',         'word' }, -- Words
			{ '^%(',             'lparen' }, -- Left Parentheses
			{ '^%)',             'rparen' }, -- Right Parentheses
			{ '^[%p]',           'symbol' }, -- Punctuation
		}

		while #text > 0 do
			local found = false
			for _, pattern in ipairs(patterns) do
				local token = text:match(pattern[1])
				if token then
					if token == '"' or token == '\'' then
						local i = 2
						while text:sub(i, i) ~= token do
							if text:sub(i, i) == '\\' then
								i = i + 1
							end
							i = i + 1
						end
						token = text:sub(1, i)
					end

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

		tokens = LUA.tokens.remove_noinstall_blocks(tokens)
		tokens = LUA.tokens.replace_build_replace_blocks(tokens)
		tokens = LUA.tokens.strip(tokens)
		return LUA.tokens.join(tokens)
	end,

	--- Compile a string of Lua code into Lua bytecode.
	--- @param text string
	--- @return string
	compile = function(text)
		local switch = false
		local function loadfn()
			if switch then return nil end
			switch = true
			return text
		end

		local fn = load(loadfn)
		if not fn then
			error(
				'COMPILER BUG: Failed to compile Lua text into bytecode!\nTHIS IS A BUG IN THE COMPILER, PLEASE REPORT IT!')
		end

		local dump = string.dump(fn)

		--Strip debug information from a dumped chunk
		--This decreases the size of the bytecode
		local version, format, endian, int, size, ins, num = dump:byte(5, 11)
		local subint
		if endian == 1 then
			subint = function(dump, i, l)
				local val = 0
				for n = l, 1, -1 do
					val = val * 256 + dump:byte(i + n - 1)
				end
				return val, i + l
			end
		else
			subint = function(dump, i, l)
				local val = 0
				for n = 1, l, 1 do
					val = val * 256 + dump:byte(i + n - 1)
				end
				return val, i + l
			end
		end
		local strip_function
		strip_function = function(dump)
			local count, offset = subint(dump, 1, size)
			local stripped, dirty = string.rep("\0", size), offset + count
			offset = offset + count + int * 2 + 4
			offset = offset + int + subint(dump, offset, int) * ins
			count, offset = subint(dump, offset, int)
			for n = 1, count do
				local t
				t, offset = subint(dump, offset, 1)
				if t == 1 then
					offset = offset + 1
				elseif t == 4 then
					offset = offset + size + subint(dump, offset, size)
				elseif t == 3 then
					offset = offset + num
				end
			end
			count, offset = subint(dump, offset, int)
			stripped = stripped .. dump:sub(dirty, offset - 1)
			for n = 1, count do
				local proto, off = strip_function(dump:sub(offset, -1))
				stripped, offset = stripped .. proto, offset + off - 1
			end
			offset = offset + subint(dump, offset, int) * int + int
			count, offset = subint(dump, offset, int)
			for n = 1, count do
				offset = offset + subint(dump, offset, size) + size + int * 2
			end
			count, offset = subint(dump, offset, int)
			for n = 1, count do
				offset = offset + subint(dump, offset, size) + size
			end
			stripped = stripped .. string.rep("\0", int * 3)
			return stripped, offset
		end

		return dump:sub(1, 12) .. strip_function(dump:sub(13, -1))
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

		_requires_cache = {},
		_rqid = 0,

		--- Recursively parse require statements and split into a function call and the rest of the program.
		--- @param tokens LUA.Token[]
		--- @return LUA.Token[]
		_extract_requires = function(tokens)
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
					if not LUA.tokens._requires_cache[file] then
						LUA.tokens._requires_cache[file] = {}
						LUA.tokens._requires_cache[file] = {
							tokens = LUA.tokens._extract_requires(LUA.tokenize(fp:read('*a'))),
							id = 'RQ' .. LUA.tokens._rqid,
						}
						LUA.tokens._rqid = LUA.tokens._rqid + 1
					end

					table.insert(new_tokens, { text = LUA.tokens._requires_cache[file].id, type = 'word' })
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
					if not LUA.tokens._requires_cache[file] then
						LUA.tokens._requires_cache[file] = {}
						LUA.tokens._requires_cache[file] = {
							tokens = LUA.tokens._extract_requires(LUA.tokenize(fp:read('*a'))),
							id = 'RQ' .. LUA.tokens._rqid,
						}
						LUA.tokens._rqid = LUA.tokens._rqid + 1
					end

					table.insert(new_tokens, { text = LUA.tokens._requires_cache[file].id, type = 'word' })
					table.insert(new_tokens, { text = '(', type = 'lparen' })
					table.insert(new_tokens, { text = ')', type = 'rparen' })

					i = get_next_index(tokens, i, 'string')
					fp:close()
				else
					table.insert(new_tokens, tokens[i])
				end
				i = i + 1
			end

			return new_tokens
		end,

		--- Replace all require calls with the appropriate file contents.
		--- @param tokens LUA.Token[]
		--- @return LUA.Token[]
		replace_requires = function(tokens)
			LUA.tokens._requires_cache = {}

			local program = LUA.tokens._extract_requires(tokens)

			local result = {}
			for _, token_list in pairs(LUA.tokens._requires_cache) do
				table.insert(result, { text = 'function', type = 'word' })
				table.insert(result, { text = token_list.id, type = 'word' })
				table.insert(result, { text = '()', type = 'lparen' })
				for _, token in ipairs(token_list.tokens) do
					table.insert(result, token)
				end
				table.insert(result, { text = 'end', type = 'word' })
			end

			for _, token in ipairs(program) do
				table.insert(result, token)
			end

			return result
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

		--- Remove any blocks of code that are wrapped in `--[[no-=install]]` ... `--[[/no-install]]` comments.
		--- @param tokens LUA.Token[]
		--- @return LUA.Token[]
		remove_noinstall_blocks = function(tokens)
			local new_tokens = {}
			local i = 1
			while i <= #tokens do
				if tokens[i].type == 'comment' and tokens[i].text == '--[[no-install]]' then
					while tokens[i].type ~= 'comment' or tokens[i].text ~= '--[[/no-install]]' do
						i = i + 1
					end
				else
					table.insert(new_tokens, tokens[i])
				end
				i = i + 1
			end
			return new_tokens
		end,


		--- Replace all blocks of code that are wrapped in `--[[build-replace=...]]` ... `--[[/build-replace]]` comments with the specified file contents.
		--- @param tokens LUA.Token[]
		--- @return LUA.Token[]
		replace_build_replace_blocks = function(tokens)
			local new_tokens = {}
			local i = 1
			while i <= #tokens do
				if tokens[i].type == 'comment' and tokens[i].text:match('^%-%-%[%[build%-replace=(.-)%]%]') then
					local file = tokens[i].text:match('^%-%-%[%[build%-replace=(.-)%]%]')
					local fp = io.open(file)
					if not fp then
						error('ERROR: File not found: ' .. file)
					end
					local text = fp:read('*a')
					fp:close()

					--Escape the text so it can be used in a Lua string
					text = text:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('"', '\\"')
					table.insert(new_tokens, { text = '"' .. text .. '"', type = 'string' })

					while tokens[i].type ~= 'comment' or tokens[i].text ~= '--[[/build-replace]]' do
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
