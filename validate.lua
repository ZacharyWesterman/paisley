local found_error = false
local function report_error(msg)
	found_error = true
	print('ERROR: '..msg)
end

--[[Verify that functions are all set up correctly.]]
local funcs = require 'src.compiler.functions'
local indices, name, config = {}
local types = {['null']=true, ['boolean']=true, ['number']=true, ['string']=true, ['array']=true, ['any']=true}

local function check_config(name, config)
	--Config can either be a number, or a valid config.
	if type(config) ~= 'number' and type(config) ~= 'table' then
		report_error('Function definition for "'..name..'" must be either an integer or a function signature config.')
		return
	end
	if type(config) == 'number' then
		--Make sure indices of separate functions don't overlap
		if indices[config] then
			report_error('Function "'..name..'" must have a unique index! Currently shares an index with "'..indices[config]..'".')
		else
			indices[config] = name
		end
		return
	end

	--Make sure the function has some number of parameters specified
	local max_param_ct = -1
	local min_param_ct = 999999999
	if type(config.param_ct) ~= 'table' or #config.param_ct == 0 then
		report_error('Function "'..name..'" must have a number of params specified, e.g. to specify 0 or 1 params are valid, put "param_ct = {0,1}" in the definition.')
	else
		local i
		for i = 1, #config.param_ct do
			local c = config.param_ct[i]
			if type(c) == 'string' and c:match('^%d+%+$') then
				max_param_ct = 999999999
				min_param_ct = math.min(min_param_ct, tonumber(c:sub(1,#c-1)))
			elseif type(c) == 'number' and c >= 0 and math.floor(c) == c then
				max_param_ct = math.max(max_param_ct, c)
				min_param_ct = math.min(min_param_ct, c)
			else
				report_error('Parameter '..i..' of function "'..name..'" must be a positive integer or a string of the form "1+", "2+", etc.')
			end
		end
	end

	--Check that the function has a valid output type defined.
	if type(config.out) ~= 'string' or config.out == '' then
		report_error('Function "'..name..'" must return a value of some type! To indicate that it returns nothing, put "out = \'null\'" in the definition.')
	elseif not types[config.out] then
		report_error('Function "'..name..'" has an invalid return type "'..config.out..'".')
	end

	--Check that all of the function's input types are valid.
	if type(config.valid) ~= 'table' then
		report_error('Valid input spec for function "'..name..'" must be a table of the form {{\'p1_type1\', \'p2_type1\'}, {\'p2_type1\', \'p2_type2\'}}.')
	else
		local i
		for i = 1, #config.valid do
			local p = config.valid[i]
			--Check the number of params, but only if we haven't already had an error calculating that number.
			if min_param_ct <= max_param_ct and (#p == 0 or #p > max_param_ct) then
				local amt = 'least 1'
				if #p > max_param_ct then amt = 'mist '..max_param_ct end
				report_error('Param set '..i..' for function "'..name..'" has '..#p..' params, but it must have at '..amt..'.')
			end

			--Check param types
			local k
			for k = 1, #p do
				if not types[p[k]] then
					report_error('Param type '..k..' of param set '..i..' for function "'..name..'" is not a valid type.')
				end
			end
		end
	end

	--Make sure there's a rule for constant folding.
	if config.fold == nil then
		report_error('Function "'..name..'" has no rule for constant folding. To indicate that this is a non-deterministic function, put "fold = false" in the definition.')
	elseif config.fold and type(config.fold) ~= 'function' then
		report_error('Constant folding rule for function "'..name..'" must be a function!')
	end

	--Index MUST be defined
	if config.index == nil then
		report_error('Function definition for "'..name..'" must have an index! If you want to indicate that this function gets optimized away, put "index = false" in the definition.')
		return
	end
	if not config.index then return end

	--Indices must be integers
	if type(config.index) ~= 'number' or math.floor(config.index) ~= config.index then
		report_error('Function index for "'..name..'" must be an integer!')
		return
	end

	--Make sure indices of separate functions don't overlap
	if indices[config.index] then
		report_error('Function "'..name..'" must have a unique index! Currently shares an index with "'..indices[config.index]..'".')
	else
		indices[config.index] = name
	end
end

for name, config in pairs(funcs) do check_config(name, config) end


local lexer = require 'src.compiler.lexer'
local iter = lexer('for i in {1,2,3} do print "{^"')

while iter.get() do end
if #iter.err() > 0 then
	local err, i = iter.err()
	for i = 1, #err do
		print(err[i])
	end
end