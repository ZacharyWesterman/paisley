local fs = require 'src.util.filesystem'

return function(vm) vm.push(fs.file_size(std.str(vm.pop()[1]))) end
