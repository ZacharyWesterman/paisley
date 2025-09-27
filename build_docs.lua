#!/usr/bin/env lua

local function_signature = require 'src.compiler.semantics.signature'
require 'src.compiler.tokens'
require 'src.compiler.type_signature'
require 'src.compiler.functions.codes'
require 'src.compiler.functions.params'
require 'src.compiler.functions.types'
require 'src.shared.stdlib'

local document = {}

for name, info in pairs(TYPESIG) do
	if type(name) == 'string' then
		if info.category == nil then
			info.category = 'misc'
		end

		if document[info.category] == nil then
			document[info.category] = {}
		end
		table.insert(document[info.category], { name = name, info = info })
	end
end

-- Sort the document by category
local new_document = {}
for category, funcs in pairs(document) do
	table.insert(new_document, { category = category, funcs = funcs })
end
table.sort(new_document, function(a, b) return a.category < b.category end)

-- Print the documentation
print('# Paisley Standard Library Functions\n')

for _, entry in ipairs(new_document) do
	local title = entry.category:gsub('(%l)(%w*)', function(x, y) return x:upper() .. y end)
	if title:find(':') then
		print('### ' .. title:gsub('^(%w+):(%w+)', '%2'))
	else
		print('## ' .. title)
	end

	table.sort(entry.funcs, function(a, b) return a.name < b.name end)
	for _, func in ipairs(entry.funcs) do
		local return_type = func.info.out
		if type(return_type) ~= 'table' then return_type = TYPE_ANY end
		print('- `' ..
			func.name ..
			'(' .. function_signature(func.name) .. ') -> ' .. TYPE_TEXT(return_type) .. '`')
		print('  - ' .. func.info.description)
	end
	print()
end
