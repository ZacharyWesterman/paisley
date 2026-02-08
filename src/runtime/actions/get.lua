return function(vm, line, p1, p2)
	if p1 == '@' then
		--List-of-params variable
		if #INSTR_STACK > 0 then
			vm.push(INSTR_STACK[#INSTR_STACK])
		else
			--If no params, then get argv
			---@diagnostic disable-next-line
			vm.push(PGM_ARGS or {})
		end
	elseif p1 == '$' then
		--List-of-commands variable
		local res = {}
		for k in pairs(BUILTIN_COMMANDS --[[@as table]]) do table.insert(res, k) end
		for k in pairs(ALLOWED_COMMANDS --[[@as table]]) do table.insert(res, k) end
		table.sort(res)
		vm.push(res)
	elseif p1 == '_VARS' then
		--List-of-vars variable
		vm.push(VARS)
	elseif p1 == '_VERSION' then
		--Version variable
		---@diagnostic disable-next-line
		vm.push(VERSION)
	else
		local v = VARS[p1]
		if v == NULL then vm.push(nil) else vm.push(v) end
	end
end
