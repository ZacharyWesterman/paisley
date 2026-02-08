local fs = require 'src.util.filesystem'

return function(vm)
	local v = vm.pop()
	vm.push(fs.dir_create(std.str(v[1]), std.bool(v[2])))
end
