#include "keys.hpp"

void keys(Context &context) noexcept
{
	// Get the keys of an object or array.
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0];

	std::vector<Value> keys;

	if (std::holds_alternative<std::vector<Value>>(value))
	{
		auto array = std::get<std::vector<Value>>(value);

		for (int i = 0; i < (int)array.size(); i++)
		{
			keys.push_back(i + 1);
		}
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(value))
	{
		auto object = std::get<std::map<std::string, Value>>(value);

		for (const auto &pair : object)
		{
			keys.push_back(pair.first);
		}
	}

	context.stack.push(keys);
}
