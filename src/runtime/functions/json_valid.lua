local json = require 'src.shared.json'

return function(vm)
	local v = vm.pop()
	if type(v[1]) ~= 'string' then
		vm.push(false)
	else
		vm.push(json.verify(v[1]))
	end
end
