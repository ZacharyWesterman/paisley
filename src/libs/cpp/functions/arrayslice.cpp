#include "arrayslice.hpp"

void arrayslice(Context &context) noexcept
{
	int end = context.stack.pop().to_number();
	int start = context.stack.pop().to_number();

	int length = end - start + 1;
	if (length > 32768)
	{
		context.warn("Attempted to create an array with " + std::to_string(length) + " elements (max is 32768). Array truncated.");
		end = start + 32767;
		length = 32768;
	}

	if (length < 0)
	{
		length = 0;
	}

	std::vector<Value> result;
	result.reserve(length);

	for (int i = start; i <= end; i++)
	{
		const Value value(i);
		result.push_back(value);
	}

	context.stack.push(result);
}
