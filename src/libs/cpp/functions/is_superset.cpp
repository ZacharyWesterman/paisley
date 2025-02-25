#include "is_superset.hpp"
#include <algorithm>

void is_superset(Context &context) noexcept
{
	// Check if the first array is a superset of the second array.
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	if (std::holds_alternative<std::vector<Value>>(params[0]) && std::holds_alternative<std::vector<Value>>(params[1]))
	{
		auto array1 = std::get<std::vector<Value>>(params[0]);
		auto array2 = std::get<std::vector<Value>>(params[1]);

		bool result = true;
		for (const Value &value : array2)
		{
			if (std::find(array1.begin(), array1.end(), value) == array1.end())
			{
				result = false;
				break;
			}
		}

		if (result)
		{
			result = array1.size() >= array2.size();
		}
		context.stack.push(result);
	}
	else
	{
		context.warn("Is superset requires two arrays. Result may be unexpected.");
		context.stack.push(false);
	}
}
