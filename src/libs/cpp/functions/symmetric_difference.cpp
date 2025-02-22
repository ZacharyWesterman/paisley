#include "symmetric_difference.hpp"
#include <algorithm>

void symmetric_difference(Context &context) noexcept
{
	// Find the symmetric difference of two arrays.
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
		for (const Value &value : array2)
		{
			if (std::find(array1.begin(), array1.end(), value) == array1.end())
			{
				result.push_back(value);
			}
		}

		context.stack.push(result);
	}
	else
	{
		context.warn("Symmetric difference requires two arrays. Result may be unexpected.");

		if (std::holds_alternative<std::vector<Value>>(params[0]))
		{
			context.stack.push(params[0]);
		}
		else if (std::holds_alternative<std::vector<Value>>(params[1]))
		{
			context.stack.push(params[1]);
		}
		else
		{
			context.stack.push(std::vector<Value>());
		}
	}
}
