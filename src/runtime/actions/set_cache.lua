local json = require "src.shared.json"

return function(vm, line, p1, p2)
	local params = {}
	if #INSTR_STACK > 0 then params = INSTR_STACK[#INSTR_STACK] end

	if not MEMOIZE_CACHE[p1] then MEMOIZE_CACHE[p1] = {} end
	MEMOIZE_CACHE[p1][json.stringify(params)] = V5
	vm.push(V5)
end
