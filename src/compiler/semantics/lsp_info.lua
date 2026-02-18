--This module only gets called when running as a language server.
--It dumps detailed info about various structures, which can be used by vscode or other editors.

local FUNCSIG = require "src.compiler.semantics.signature"

local config = {
	labels = {},
	variables = {},
}
local vscode = require "src.util.vscode"

local kwds = require "src.compiler.keywords"
local keywords = {}
for key, val in pairs(kwds) do
	keywords[val] = key
end

local function return_text(type, desc)
	local text = '\n**Returns:** '
	if desc then text = text .. '\n  (' end
	text = text .. TYPE_TEXT(type, true)
	if desc then text = text .. ') ' .. desc end
	return text
end

local function data_type(var, type)
	return vscode.color(var, vscode.theme.var) .. ': ' ..
		(type and TYPE_TEXT(type, true) or vscode.color('unknown', vscode.theme.gray))
end

local function command_lsp(token, filename)
	local var = token.children[1]
	local cmd = var
	if token.id == TOK.inline_command then cmd = cmd.children[1] end

	if cmd.value then
		if var.id == TOK.call_stmt then
			if config.labels[cmd.text] then
				local tp = config.labels[cmd.text].type
				if EXACT_TYPE(tp, TYPE_NULL) then
					INFO.info(cmd.span,
						'The ' .. keywords[TOK.kwd_function] .. ' `' ..
						cmd.text ..
						'` always returns null, so using an inline command eval here is not helpful',
						filename)
				end
			end
		else
			local tp
			if ALLOWED_COMMANDS[cmd.value] then
				tp = ALLOWED_COMMANDS[cmd.value]
			else
				tp = BUILTIN_COMMANDS[cmd.value]
			end

			if token.id == TOK.command and tp then
				local text = '## ' ..
					vscode.color(cmd.text, vscode.theme.command) .. '\n' .. CMD_DESCRIPTION[cmd.text] .. return_text(tp)
				INFO.hint(cmd.span, text, filename)
			end

			if token.id == TOK.inline_command and EXACT_TYPE(tp, TYPE_NULL) then
				INFO.info(cmd.span,
					'The command `' ..
					cmd.text ..
					'` always returns null, so using an inline command eval here is not helpful', filename)
			end
		end
	end
end

local function function_text(token)
	local text = '## ' ..
		vscode.color(keywords[TOK.kwd_function], vscode.theme.keyword) ..
		' ' .. vscode.color(token.text, vscode.theme.sub)

	local tags = {}
	if token.memoize then table.insert(tags, 'memoized') end
	if token.tags.private then table.insert(tags, 'private') end
	-- if token.tags.export then table.insert(tags, 'exported') end
	if token.tags.elide then table.insert(tags, 'elision allowed') end
	if #tags > 0 then
		text = text .. '\n*' .. vscode.color(table.concat(tags, ', '), vscode.theme.gray) .. '*'
	end

	if token.tags.text then
		text = text .. '\n' .. token.tags.text
	end

	if token.tags.params then
		text = text .. '\n**Params**:'
		for i, param in ipairs(token.tags.params) do
			text = text .. '\n' .. i .. '. '
			if param.name then
				text = text .. '**' .. param.name .. '** '
			end
			text = text .. '(' .. TYPE_TEXT(param.type, true) .. ')'
			if param.desc then text = text .. ' ' .. param.desc end
		end
	end

	if token.tags.returns then
		--Print return info
		local retn = token.tags.returns
		text = text .. return_text(retn.type, retn.desc)
	elseif token.type then
		text = text .. return_text(token.type)
	end

	if token.tags.error then
		--Print the situations in which the function might raise an error.
		text = text .. '\n**Errors**:'
		for _, t in ipairs(token.tags.error) do
			text = text .. '\n- ' .. t
		end
	end

	return text
end

local function func_call_lsp(token, filename)
	local name = token.text
	if not BUILTIN_FUNCS[name] then return end

	local funcsig = '**' ..
		vscode.color(name, vscode.theme.func) .. '**(' .. FUNCSIG(name, true) .. ') &rArr; '
	if TYPESIG[name].out == 1 then
		--Return type is the same as 1st param
		local types = {}
		for i, k in ipairs(TYPESIG[name].valid) do
			table.insert(types, k[1])
		end
		funcsig = funcsig .. std.join(types, '|', TYPE_TEXT)
	else
		funcsig = funcsig .. TYPE_TEXT(TYPESIG[name].out, true)
	end

	local text = funcsig .. '\n' .. TYPESIG[name].description
	INFO.hint(token.span, text, filename)
end

return {
	init = function(labels, variables)
		config.labels = labels
		config.variables = variables
	end,

	enter = {
		[TOK.sub_ref] = {
			function(token, filename)
				INFO.func_call(token.span, filename)
			end,

			function(token, filename)
				if not config.labels[token.text] then return end
				--Print function signature
				local text = function_text(config.labels[token.text])

				--Print function location
				text = text .. '\n\n*'
				local fname = config.labels[token.text].filename or filename
				if fname and fname ~= INFO.root_file then
					text = text .. fname .. ' : '
				else
					text = text .. 'Defined on line '
				end
				text = text .. config.labels[token.text].span.from.line .. '*'

				INFO.hint(token.span, text, filename)
			end,
		},

		[TOK.func_ref] = {
			function(token, filename)
				INFO.func_call(token.span, filename)
			end,

			func_call_lsp,
		},

		--Print info about each built-in function
		[TOK.func_call] = {
			func_call_lsp,

			function(token, filename)
				if token.text ~= 'env_get' then return end

				INFO.constant(token.span, filename)

				local text = data_type('_ENV', TYPE_ENV)
				text = text .. '\nReads an environment variable when indexed.'
				text = text ..
					'\nNote that unlike other variables, only individual keys of `_ENV` are allowed to be accessed, not the entire object.'

				INFO.hint(token.span, text, filename)
			end,
		},

		--Print info about each command
		[TOK.command] = {
			command_lsp,
		},
		[TOK.inline_command] = {
			command_lsp,
		},

		[TOK.call_stmt] = {
			function(token, filename)
				token = token.children[1]
				if config.labels[token.text] then
					--Print function signature
					local text = function_text(config.labels[token.text])

					--Print function location
					text = text .. '\n\n*'
					local fname = config.labels[token.text].filename or filename
					if fname and fname ~= INFO.root_file then
						text = text .. fname .. ' : '
					else
						text = text .. 'Defined on line '
					end
					text = text .. config.labels[token.text].span.from.line .. '*'

					INFO.hint(token.span, text, filename)
				end
			end,
		},

		--Print information about function definitions
		[TOK.function_def] = {
			function(token, filename)
				local to_col = 9999
				if token.children[1].span.from.line == token.span.from.line then
					to_col = token.children[1].span.from.col - 1
				end

				INFO.hint({
					from = token.span.from,
					to = {
						line = token.span.from.line,
						col = to_col,
					}
				}, function_text(token), filename)
			end,

			--Warn if the function is never used
			function(token, filename)
				if not token.is_referenced and not EXPORT_LINES[token.span.from.line] then
					INFO.dead_code(token.span,
						'The ' .. keywords[TOK.kwd_function] .. ' `' .. token.text .. '` is never used.',
						filename)
				end
			end,
		},

		[TOK.kv_for_stmt] = {
			function(token, filename)
				local var = token.children[1]
				INFO.hint(var.span, data_type(var.text, var.type), filename)
				var = token.children[2]
				INFO.hint(var.span, data_type(var.text, var.type), filename)
			end,
		},

		[TOK.for_stmt] = {
			function(token, filename)
				local var = token.children[1]
				INFO.hint(var.span, data_type(var.text, var.type), filename)
			end,
		},

		[TOK.let_stmt] = {
			function(token, filename)
				local json = require 'src.shared.json'

				local var = token.children[1]
				local text = data_type(var.text, var.type)
				local span = var.span

				if var.value ~= nil then
					text = text .. ' = ' .. std.escape_xml(json.stringify(var.value))
				end

				for _, kid in ipairs(var.children) do
					text = text .. '\n' .. data_type(kid.text, kid.type)
					span = Span:merge(span, kid.span)
				end

				if token.tags and token.tags.text and #token.tags.text > 0 then
					text = text .. '\n' .. token.tags.text
				end

				INFO.hint(span, text, filename)
			end,
		},

		[TOK.variable] = {
			function(token, filename)
				local builtin_vars = {
					_VARS = function()
						return '\nContains the names and values of all global variables in the current script as key-value pairs.'
					end,
					_VERSION = function()
						local text = ''
						if VERSION then text = text .. ' = "' .. VERSION .. '"' end
						text = text ..
							'\nContains the version number of the Paisley runtime environment, formatted as `MAJOR.MINOR.PATCH`.'
						return text
					end,
					['$'] = function()
						return '\nContains the names of all the commands the current script has access to.'
					end,
					['@'] = function()
						return
						'\nIf used inside a function, this contains any arguments passed to the function.\nIf used outside of a function, it instead contains any run-time arguments passed to the current script.'
					end,
				}

				local text = data_type(token.text, token.type)
				local json = require 'src.shared.json'
				local val_found = false
				local val = nil
				local comment = nil

				if builtin_vars[token.text] then
					text = text .. builtin_vars[token.text]()
				else
					local v = config.variables[token.text] or {}

					local found = false
					for varname, var in pairs(v) do
						for decl_token, _ in pairs(var.decls or {}) do
							if decl_token.value then
								if val_found then
									if decl_token.value ~= val then val = nil end
								else
									val_found = true
									val = decl_token.value
								end
							end

							local t = decl_token.tags and decl_token.tags.text
							if t and #t > 0 then
								comment = t
								found = true
								break
							end
						end
						if found then break end
					end
				end

				if val ~= nil then
					text = text .. ' = ' .. std.escape_xml(json.stringify(val))
				end
				if comment then
					text = text .. '\n' .. comment
				end

				INFO.hint(token.span, text, filename)
			end,

			function(token, filename)
				local const_vars = {
					_VARS = true,
					_VERSION = true,
				}

				if const_vars[token.text] then
					INFO.constant({
						from = token.span.from,
						to = {
							line = token.span.to.line,
							col = token.span.from.col + #token.text,
						},
					}, filename)
				end
			end,
		},
	},

	exit = {},
}
