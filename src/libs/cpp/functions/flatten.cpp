#include "flatten.hpp"

std::vector<Value> flatten_recursive(const std::vector<Value> &array) noexcept
{
	std::vector<Value> result;

	for (const Value &value : array)
	{
		if (std::holds_alternative<std::vector<Value>>(value))
		{
			const auto subarray = flatten_recursive(std::get<std::vector<Value>>(value));
			result.reserve(result.size() + subarray.size());

			for (const auto &element : subarray)
			{
				result.push_back(element);
			}
		}
		else
		{
			const auto subarray = flatten_recursive(value.to_array());
			result.reserve(result.size() + subarray.size());

			for (const auto &item : subarray)
			{
				result.push_back(item);
			}
		}
	}

	return result;
}

void flatten(Context &context) noexcept
{
	// Flatten an array of any dimension into a 1D array.
	auto param = std::get<std::vector<Value>>(context.stack.pop())[0];

	if (!std::holds_alternative<std::vector<Value>>(param))
	{
		context.stack.push(flatten_recursive(param.to_array()));
		return;
	}

	context.stack.push(flatten_recursive(std::get<std::vector<Value>>(param)));
}
