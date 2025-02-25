#include "values.hpp"

void values(Context &context) noexcept
{
	// Get the values of an object or array.
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0];

	std::vector<Value> values;

	if (std::holds_alternative<std::vector<Value>>(value))
	{
		auto array = std::get<std::vector<Value>>(value);

		for (auto &i : array)
		{
			values.push_back(i);
		}
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(value))
	{
		auto object = std::get<std::map<std::string, Value>>(value);

		for (const auto &pair : object)
		{
			values.push_back(pair.second);
		}
	}

	context.stack.push(values);
}
