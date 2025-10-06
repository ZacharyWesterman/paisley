#include "flatten.hpp"

std::vector<Value> flatten_recursive(const std::vector<Value> &array, int depth) noexcept
{
	std::vector<Value> result;

	for (const Value &value : array)
	{
		if (depth > 0 && std::holds_alternative<std::vector<Value>>(value))
		{
			const auto subarray = flatten_recursive(std::get<std::vector<Value>>(value), depth - 1);
			result.reserve(result.size() + subarray.size());

			for (const auto &element : subarray)
			{
				result.push_back(element);
			}
		}
		else
		{
			result.push_back(value);
		}
	}

	return result;
}

void flatten(Context &context) noexcept
{
	// Flatten an array of any dimension into a 1D array.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto param = params[0];
	int depth = (params.size() > 1) ? params[1].to_number() : std::numeric_limits<int>::max();

	if (!std::holds_alternative<std::vector<Value>>(param))
	{
		context.stack.push(flatten_recursive(param.to_array(), depth));
		return;
	}

	context.stack.push(flatten_recursive(std::get<std::vector<Value>>(param), depth));
}
