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
						local i = 1
						while true do
							local ix = text:find(token, i + 1, true)
							if not ix then
								error('ERROR When parsing Lua code: Unclosed string.')
							end

							i = ix
							--Ignore escaped quotes with an odd number of backslashes
							local backslashes = 0
							local b = i
							while text:sub(b - 1, b - 1) == '\\' do
								backslashes = backslashes + 1
								b = b - 1
							end

							if backslashes % 2 == 0 then
								break
							end
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
	--- @param text string The Lua code.
	--- @param standalone boolean? Whether to resolve require statements.
	--- @param remove_delete_blocks boolean? Whether to remove blocks of code that are unused in the Plasma build.
	--- @param print_progress boolean? Whether to print progress messages.
	--- @return string new_code The minified Lua code.
	minify = function(text, standalone, remove_delete_blocks, print_progress)
		local tokens = LUA.tokenize(text)

		if remove_delete_blocks then
			tokens = LUA.tokens.remove_delete_blocks(tokens)
		end

		if standalone then
			tokens = LUA.tokens.replace_requires(tokens, print_progress, remove_delete_blocks)
		end

		tokens = LUA.tokens.remove_noinstall_blocks(tokens)

		if print_progress then io.stderr:write('\nInserting helper files...') end
		tokens = LUA.tokens.replace_build_replace_blocks(tokens, print_progress)

		tokens = LUA.tokens.strip(tokens)

		if print_progress then io.stderr:write('\n') end
		local result = LUA.tokens.join(tokens, print_progress)
		if print_progress then io.stderr:write('\n') end

		return result
	end,

	--- Resolve all require statements in a string of Lua code, and replace special comment blocks.
	--- @param text string The Lua code.
	--- @return string new_code The resolved Lua code.
	glue = function(text, standalone, remove_delete_blocks)
		local tokens = LUA.tokenize(text)

		if standalone then
			tokens = LUA.tokens.replace_requires(tokens)
		end

		if remove_delete_blocks then
			tokens = LUA.tokens.remove_delete_blocks(tokens)
		end

		tokens = LUA.tokens.remove_noinstall_blocks(tokens)
		tokens = LUA.tokens.replace_build_replace_blocks(tokens)
		return LUA.tokens.join(tokens)
	end,

	--- Compile a string of Lua code into Lua bytecode.
	--- @param text string The Lua code.
	--- @return string bytecode The Lua bytecode.
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

		return string.dump(fn)
	end,

	tokens = {
		--- Print a table of tokens.
		--- @param tokens LUA.Token[] The tokens to print.
		--- @return nil
		print = function(tokens)
			for _, token in ipairs(tokens) do
				print(token.type, ' = ', token.text)
			end
		end,

		--- Remove whitespace and comments from a table of tokens.
		--- @param tokens LUA.Token[] The tokens to process.
		--- @return LUA.Token[] stripped The processed tokens.
		strip = function(tokens)
			local stripped = {}
			for i, token in ipairs(tokens) do
				if token.type ~= 'space' and token.type ~= 'comment' then
					table.insert(stripped, token)
				end
			end
			return stripped
		end,

		--- Join a table of tokens into a string.
		--- @param tokens LUA.Token[] The tokens to join.
		--- @param print_progress boolean? Whether to print progress messages.
		--- @return string text The joined text.
		join = function(tokens, print_progress)
			local text = ''
			local prev = {
				type = 'space',
				text = '',
			}
			local buffer = ''

			for i, token in ipairs(tokens) do
				if prev.type == 'word' and token.type == 'word' then
					buffer = buffer .. ' '
				end
				buffer = buffer .. token.text
				prev = token

				if print_progress and i % 100 == 0 then
					io.stderr:write('\rGenerating text... ' .. math.floor(i / #tokens * 100) .. '%')
				end

				if #buffer > 4096 then
					text = text .. buffer
					buffer = ''
				end
			end
			text = text .. buffer

			if print_progress then
				io.stderr:write('\rGenerating text... 100%\n')
			end
			return text
		end,

		_requires_cache = {},
		_rqid = 0,

		--- Recursively parse require statements and split into a function call and the rest of the program.
		--- @param tokens LUA.Token[] The tokens to process.
		--- @param print_progress boolean? Whether to print progress messages.
		--- @param remove_delete_blocks boolean? Whether to remove blocks of code that are unused in the Plasma build.
		--- @return LUA.Token[] new_tokens The processed tokens.
		_extract_requires = function(tokens, print_progress, remove_delete_blocks)
			if print_progress then
				io.stderr:write('.')
			end

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
				if tokens[i].text == 'require' and match_types(tokens, i + 1, { 'string' }) then
					local file = get_next_value(tokens, i, 'string'):sub(2, -2):gsub('%.', '/') .. '.lua'
					local fp = io.open(file)
					if not fp then
						error('ERROR: File not found: ' .. file)
					end
					if not LUA.tokens._requires_cache[file] then
						local t = LUA.tokenize(fp:read('*a'))
						if remove_delete_blocks then
							t = LUA.tokens.remove_delete_blocks(t)
						end
						LUA.tokens._requires_cache[file] = {
							tokens = LUA.tokens._extract_requires(t, print_progress, remove_delete_blocks),
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
		--- @param tokens LUA.Token[] The tokens to process.
		--- @param print_progress boolean? Whether to print progress messages.
		--- @param remove_delete_blocks boolean? Whether to remove blocks of code that are unused in the Plasma build.
		--- @return LUA.Token[] new_tokens The processed tokens.
		replace_requires = function(tokens, print_progress, remove_delete_blocks)
			LUA.tokens._requires_cache = {}

			local t = tokens
			if remove_delete_blocks then
				t = LUA.tokens.remove_delete_blocks(t)
			end

			local program = LUA.tokens._extract_requires(t, print_progress, remove_delete_blocks)

			local result = {}
			for _, token_list in pairs(LUA.tokens._requires_cache) do
				--Cache for require calls.
				table.insert(result, { text = 'C' .. token_list.id, type = 'word' })
				table.insert(result, { text = '={nil,false}', type = 'lparen' })

				--Function begin
				table.insert(result, { text = 'function ' .. token_list.id, type = 'word' })
				table.insert(result, { text = '()', type = 'lparen' })

				--Function body (called with `require`).
				table.insert(result, { text = 'local fn=function', type = 'word' })
				table.insert(result, { text = '()', type = 'lparen' })
				for _, token in ipairs(token_list.tokens) do
					table.insert(result, token)
				end
				table.insert(result, { text = 'end', type = 'word' })

				--If function hasn't been called yet, call it and cache the result.
				table.insert(result, {
					text = 'if not C' .. token_list.id .. '[2] then C' .. token_list.id .. '={fn(),true} end',
					type = 'word'
				})
				table.insert(result, { text = 'return C' .. token_list.id, type = 'word' })
				table.insert(result, { text = '[1]', type = 'lparen' })

				--Function end
				table.insert(result, { text = 'end', type = 'word' })
			end

			for _, token in ipairs(program) do
				table.insert(result, token)
			end

			return result
		end,

		--- Remove any blocks of code that are wrapped in `--[[minify-delete]]` ... `--[[/minify-delete]]` comments.
		--- @param tokens LUA.Token[] The tokens to process.
		--- @return LUA.Token[] new_tokens The processed tokens.
		remove_delete_blocks = function(tokens)
			local new_tokens = {}
			local i = 1
			while i <= #tokens do
				if tokens[i].type == 'comment' and tokens[i].text == '--[[minify-delete]]' then
					local beg = i
					while tokens[i].type ~= 'comment' or tokens[i].text ~= '--[[/minify-delete]]' do
						i = i + 1
						--Check for minification errors
						if tokens[i].type == 'comment' and tokens[i].text == '--[[minify-delete]]' then
							local msg = 'ERROR: Unexpected `--[[minify-delete]]` inside a `--[[minify-delete]]` block.'
							msg = msg .. '\nCONTEXT:\n'
							for j = beg - 1, i do
								if tokens[j] then
									msg = msg .. tokens[j].text
								end
							end
							io.stderr:write(msg .. '\n')
							os.exit(1)
						end
					end
				else
					table.insert(new_tokens, tokens[i])
				end
				i = i + 1
			end
			return new_tokens
		end,

		--- Remove any blocks of code that are wrapped in `--[[no-=install]]` ... `--[[/no-install]]` comments.
		--- @param tokens LUA.Token[] The tokens to process.
		--- @return LUA.Token[] new_tokens The processed tokens.
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
		--- @param tokens LUA.Token[] The tokens to process.
		--- @param print_progress boolean? Whether to print progress messages.
		--- @return LUA.Token[] new_tokens The processed tokens.
		replace_build_replace_blocks = function(tokens, print_progress)
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

					--Minify any Lua code
					if file:match('%.lua$') then
						text = LUA.minify(text, true, _G['SANDBOX'] or false)
					end

					--Escape the text so it can be used in a Lua string
					text = text:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('"', '\\"')

					--Append the text to the new tokens
					table.insert(new_tokens, { text = '"' .. text .. '"', type = 'string' })

					--Skip to the end of the block
					while tokens[i].type ~= 'comment' or tokens[i].text ~= '--[[/build-replace]]' do
						i = i + 1
					end

					if print_progress then io.stderr:write('.') end
				else
					table.insert(new_tokens, tokens[i])
				end
				i = i + 1
			end
			return new_tokens
		end,
	},
}
