local function nodes_identical(node1, node2)
	if node1.id ~= node2.id or node1.text ~= node2.text or #node1.children ~= #node2.children or not std.equal(node1.value, node2.value) then
		return false
	end

	for i = 1, #node1.children do
		if not nodes_identical(node1.children[i], node2.children[i]) then
			return false
		end
	end

	return true
end

return nodes_identical
