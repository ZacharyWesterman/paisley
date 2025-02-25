#include "interleave.hpp"

void interleave(Context &context) noexcept
{
	// Interleave two arrays.
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	if (std::holds_alternative<std::vector<Value>>(params[0]) && std::holds_alternative<std::vector<Value>>(params[1]))
	{
		auto array1 = std::get<std::vector<Value>>(params[0]);
		auto array2 = std::get<std::vector<Value>>(params[1]);

		std::vector<Value> result;
		for (int i = 0; i < (int)array1.size() || i < (int)array2.size(); i++)
		{
			if (i < (int)array1.size())
			{
				result.push_back(array1[i]);
			}
			if (i < (int)array2.size())
			{
				result.push_back(array2[i]);
			}
		}

		context.stack.push(result);
	}
	else
	{
		context.warn("Interleave requires two arrays. Result may be unexpected.");

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
