#include "object.hpp"

void object(Context &context) noexcept
{
	// Fold an array into an object.
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0];

	if (!std::holds_alternative<std::vector<Value>>(value))
	{
		// If the value is not an array, return an empty object.
		context.stack.push(std::map<std::string, Value>());
		return;
	}

	auto array = std::get<std::vector<Value>>(value);
	std::map<std::string, Value> object;

	for (size_t i = 0; i < array.size(); i += 2)
	{
		auto key = array[i].to_string();

		if (i + 1 >= array.size())
		{
			// If the array has an odd number of elements, the last element will be null.
			object[key] = Value();
			break;
		}

		object[key] = array[i + 1];
	}

	context.stack.push(object);
}
