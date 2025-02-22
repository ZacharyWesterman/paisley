#include "is_disjoint.hpp"
#include <algorithm>

void is_disjoint(Context &context) noexcept
{
	// Check if two arrays are disjoint.
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	if (std::holds_alternative<std::vector<Value>>(params[0]) && std::holds_alternative<std::vector<Value>>(params[1]))
	{
		auto array1 = std::get<std::vector<Value>>(params[0]);
		auto array2 = std::get<std::vector<Value>>(params[1]);

		bool result = true;
		for (const Value &value : array1)
		{
			if (std::find(array2.begin(), array2.end(), value) != array2.end())
			{
				result = false;
				break;
			}
		}

		context.stack.push(result);
	}
	else
	{
		context.warn("Is disjoint requires two arrays. Result may be unexpected.");
		context.stack.push(true);
	}
}
