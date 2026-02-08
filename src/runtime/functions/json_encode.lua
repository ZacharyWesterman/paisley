local json = require 'src.shared.json'

return function(vm, line)
	local v = vm.pop()
	local indent = nil
	if std.bool(v[2]) then indent = 2 end

	local res, err = json.stringify(v[1], indent)
	if err ~= nil then
		vm.runtime_error(line, err)
	end
	vm.push(res)
end
