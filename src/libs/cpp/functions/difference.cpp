#include "difference.hpp"
#include <algorithm>

void difference(Context &context) noexcept
{
	// Find the difference of two arrays.
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	if (std::holds_alternative<std::vector<Value>>(params[0]) && std::holds_alternative<std::vector<Value>>(params[1]))
	{
		auto array1 = std::get<std::vector<Value>>(params[0]);
		auto array2 = std::get<std::vector<Value>>(params[1]);

		std::vector<Value> result;
		for (const Value &value : array1)
		{
			if (std::find(array2.begin(), array2.end(), value) == array2.end())
			{
				result.push_back(value);
			}
		}

		context.stack.push(result);
	}
	else
	{
		context.warn("Difference requires two arrays. Result may be unexpected.");

		if (std::holds_alternative<std::vector<Value>>(params[0]))
		{
			context.stack.push(params[0]);
		}
		else
		{
			context.stack.push(std::vector<Value>());
		}
	}
}
