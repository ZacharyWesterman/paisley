#include "sorted.hpp"
#include <algorithm>

void sorted(Context &context) noexcept
{
	// Check if an array is sorted in ascending order.
	auto param = std::get<std::vector<Value>>(context.stack.pop())[0];

	if (!std::holds_alternative<std::vector<Value>>(param))
	{
		context.stack.push(false);
		return;
	}

	auto array = param.to_array();
	context.stack.push(std::is_sorted(array.begin(), array.end()));
}
