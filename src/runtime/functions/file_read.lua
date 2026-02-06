local fs = require 'src.util.filesystem'

return function(vm) vm.push(fs.file_read(std.str(vm.pop()[1]))) end
