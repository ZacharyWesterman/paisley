#include "update.hpp"

void update(Context &context) noexcept
{
	// Replace an element in an array
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto array = params[0].to_array();
	int index = params[1].to_number();
	auto value = params[2];

	if (index == 0)
	{
		context.warn("Array indexes start at 1, not 0. update() will have no effect.");
		context.stack.push(array);
		return;
	}

	if (index < 0)
	{
		index += array.size();
	}
	else
	{
		index -= 1;
	}

	if (index < 0 || index >= (int)array.size())
	{
		context.warn("Array index out of bounds. update() will have no effect.");
		context.stack.push(array);
		return;
	}

	array[static_cast<size_t>(index)] = value;
	context.stack.push(array);
}
