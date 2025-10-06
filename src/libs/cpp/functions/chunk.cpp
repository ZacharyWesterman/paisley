#include "chunk.hpp"

// Group elements of an array into smaller arrays of a specified size.
// If the array can't be split evenly, the final chunk will be smaller than the specified size.
void chunk(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	if (!std::holds_alternative<std::vector<Value>>(params[0]))
	{
		context.warn("WARNING: chunk() first argument is not an array! Coercing to an empty array.");
		context.stack.push(std::vector<Value>{});
		return;
	}

	const auto array = std::get<std::vector<Value>>(params[0]);
	const long size = params[1].to_number();

	if (size < 1)
	{
		context.stack.push(std::vector<Value>{});
		return;
	}

	std::vector<Value> chunk;
	std::vector<Value> result;

	for (size_t i = 0; i < array.size(); i++)
	{
		chunk.push_back(array[i]);

		if (chunk.size() == (size_t)size)
		{
			result.push_back(chunk);
			chunk.clear();
		}
	}
	if (!chunk.empty())
	{
		result.push_back(chunk);
	}
	context.stack.push(result);
}
