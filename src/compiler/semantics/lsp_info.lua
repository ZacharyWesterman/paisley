--This module only gets called when running as a language server.
--It dumps detailed info about various structures, which can be used by vscode or other editors.

local FUNCSIG = require "src.compiler.semantics.signature"

local config = {
	labels = {},
}
local vscode = require "src.util.vscode"

local kwds = require "src.compiler.keywords"
local keywords = {}
for key, val in pairs(kwds) do
	keywords[val] = key
end

local function return_text(type)
	return '\n**Returns:** ' .. TYPE_TEXT(type, true)
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
		if var.id == TOK.gosub_stmt then
			if config.labels[cmd.text] then
				local tp = config.labels[cmd.text].type
				if EXACT_TYPE(tp, TYPE_NULL) then
					INFO.info(cmd.span,
						'The ' .. keywords[TOK.kwd_subroutine] .. ' `' ..
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

return {
	init = function(labels)
		config.labels = labels
	end,

	enter = {
		--Print info about each built-in function
		[TOK.func_call] = {
			function(token, filename)
				local name = token.text
				local funcsig = '**' ..
					vscode.color(name, vscode.theme.func) .. '**(' .. FUNCSIG(name, true) .. ') &rArr; '
				if name == 'reduce' then
					funcsig = funcsig .. 'bool|number'
				elseif TYPESIG[name].out == 1 then
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
			end,
		},

		--Print info about each command
		[TOK.command] = {
			command_lsp,
		},
		[TOK.inline_command] = {
			command_lsp,
		},

		[TOK.gosub_stmt] = {
			function(token, filename)
				token = token.children[1]
				if config.labels[token.text] then
					--Print subroutine signature
					local text = '## ' ..
						vscode.color(keywords[TOK.kwd_subroutine], vscode.theme.keyword) ..
						' ' .. vscode.color(token.text, vscode.theme.sub)

					local tp = config.labels[token.text].type
					if tp then
						text = text .. return_text(tp)
					end

					--Print subroutine location
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

		--Print information about subroutine definitions
		[TOK.subroutine] = {
			function(token, filename)
				local text = '## ' ..
					vscode.color(keywords[TOK.kwd_subroutine], vscode.theme.keyword) ..
					' ' .. vscode.color(token.text, vscode.theme.sub)
				if token.type then
					text = text .. return_text(token.type)
				end

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
				}, text, filename)
			end,

			--Warn if the subroutine is never used
			function(token, filename)
				if not token.is_referenced and not EXPORT_LINES[token.span.from.line] then
					local span = {
						from = token.span.from,
						to = {
							line = token.span.to.line,
							col = token.span.to.col - 4,
						}
					}

					INFO.dead_code(span,
						'The ' .. keywords[TOK.kwd_subroutine] .. ' `' .. token.text .. '` is never used.',
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
				local var = token.children[1]
				INFO.hint(var.span, data_type(var.text, var.type), filename)
				for _, kid in ipairs(var.children) do
					INFO.hint(kid.span, data_type(kid.text, kid.type), filename)
				end
			end,
		},

		[TOK.variable] = {
			function(token, filename)
				local text = data_type(token.text, token.type)
				INFO.hint(token.span, text, filename)
			end,
		},
	},

	exit = {},
}
