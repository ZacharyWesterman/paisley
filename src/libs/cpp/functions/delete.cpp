#include "delete.hpp"

void _delete(Context &context) noexcept
{
	// Remove an element from an array
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto array = params[0].to_array();
	int index = params[1].to_number();

	if (index == 0)
	{
		context.warn("Array indexes start at 1, not 0. delete() will have no effect.");
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
		context.warn("Array index out of bounds. delete() will have no effect.");
		context.stack.push(array);
		return;
	}

	array.erase(array.begin() + index);
	context.stack.push(array);
}
