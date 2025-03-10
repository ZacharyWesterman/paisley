#include "update.hpp"

void update(Context &context) noexcept
{
	// Replace an element in an array or object
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto value = params[2];

	if (std::holds_alternative<std::map<std::string, Value>>(params[0]))
	{
		auto object = std::get<std::map<std::string, Value>>(params[0]);
		auto key = params[1].to_string();

		// If the value is null, remove the key from the object
		if (std::holds_alternative<Null>(value))
		{
			object.erase(key);
		}
		else
		{
			object[key] = value;
		}

		context.stack.push(object);
		return;
	}
	else if (std::holds_alternative<std::vector<Value>>(params[0]))
	{
		auto array = std::get<std::vector<Value>>(params[0]);
		int index = params[1].to_number();

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
		return;
	}

	context.warn("First argument to update() must be an array or object. update() will have no effect.");
	context.stack.push(params[0]);
}
