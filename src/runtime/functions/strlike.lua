return (require 'src.runtime.runtime_helpers').operator(std.str, function(a, b) return a:match(b) ~= nil end)
