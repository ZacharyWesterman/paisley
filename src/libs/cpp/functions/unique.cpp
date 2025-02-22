#include "unique.hpp"
#include <algorithm>

void unique(Context &context) noexcept
{
	// Remove duplicate values from an array.
	auto array = std::get<std::vector<Value>>(context.stack.pop())[0].to_array();
	std::vector<Value> result;

	for (const Value &value : array)
	{
		if (std::find(result.begin(), result.end(), value) == result.end())
		{
			result.push_back(value);
		}
	}

	context.stack.push(result);
}
