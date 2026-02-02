return (require 'src.runtime.runtime_helpers').operator(std.num,
	function(a, b) if a == 0 then return 0 else return a ^ b end end)
