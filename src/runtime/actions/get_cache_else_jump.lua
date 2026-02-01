local json = require "src.shared.json"

return function(vm, line, p1, p2)
	local params = {}
	if #INSTR_STACK > 0 then params = INSTR_STACK[#INSTR_STACK] end

	--If cache value exists, place it in the "command return" slot.
	if MEMOIZE_CACHE[p1] then
		local serialized = json.stringify(params)
		if MEMOIZE_CACHE[p1][serialized] ~= nil then
			vm.push(MEMOIZE_CACHE[p1][serialized])
			return
		end
	end

	--if cache doesn't exist, jump.
	CURRENT_INSTRUCTION = p2
end
