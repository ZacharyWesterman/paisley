local fs = require 'src.util.filesystem'

return function(vm)
	local v = vm.pop()
	vm.push(fs.file_copy(std.str(v[1]), std.str(v[2]), std.bool(v[3])))
end
