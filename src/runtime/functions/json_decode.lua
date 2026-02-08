local json = require 'src.shared.json'

return function(vm, line)
	local v = vm.pop()

	if type(v[1]) ~= 'string' then
		vm.runtime_error(line, 'Input to json_decode is not a string')
	end

	local res, err = json.parse(v[1], true)
	if err ~= nil then
		vm.runtime_error(line, err)
	end

	vm.push(res)
end
