return (require 'src.runtime.runtime_helpers').operator(std.bool, function(a, b) return (a or b) and not (a and b) end)
