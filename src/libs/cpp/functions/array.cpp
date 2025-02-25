#include "array.hpp"

void array(Context &context) noexcept
{
	// Unfold an object into an array.
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0];

	if (!std::holds_alternative<std::map<std::string, Value>>(value))
	{
		// If the value is not an object, return an empty array.
		context.stack.push(std::vector<Value>());
		return;
	}

	auto object = std::get<std::map<std::string, Value>>(value);
	std::vector<Value> array;

	for (const auto &pair : object)
	{
		array.push_back(pair.first);
		array.push_back(pair.second);
	}

	context.stack.push(array);
}
