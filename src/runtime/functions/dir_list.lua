local fs = require 'src.util.filesystem'

return function(vm)
	local v = vm.pop()
	vm.push(fs.dir_list(std.str(v[1])))
end
