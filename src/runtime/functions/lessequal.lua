return function(vm) vm.push(std.compare(vm.pop(), vm.pop(), function(p1, p2) return p1 >= p2 end)) end
