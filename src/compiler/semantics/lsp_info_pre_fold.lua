--This module only gets called when running as a language server.
--It dumps detailed info about various structures, which can be used by vscode or other editors.

local FUNCSIG = require "src.compiler.semantics.signature"

local vscode = require "src.util.vscode"

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
		---@diagnostic disable-next-line
		funcsig = funcsig .. TYPE_TEXT(TYPESIG[name].out, true)
	end

	local text = funcsig .. '\n\n' .. TYPESIG[name].description
	INFO.hint(token.span, text, filename)
end

return {
	enter = {
		--Print info about each built-in function
		[TOK.func_call] = {
			func_call_lsp,
		},
	},

	exit = {},
}
