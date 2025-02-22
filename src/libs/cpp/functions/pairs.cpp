#include "pairs.hpp"

void pairs(Context &context) noexcept
{
	// Convert an array or object into an array of pairs.
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0];

	std::vector<Value> pairs;

	if (std::holds_alternative<std::vector<Value>>(value))
	{
		auto array = std::get<std::vector<Value>>(value);

		for (int i = 0; i < (int)array.size(); i++)
		{
			pairs.push_back({i + 1, array[i]});
		}
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(value))
	{
		auto object = std::get<std::map<std::string, Value>>(value);

		for (const auto &pair : object)
		{
			pairs.push_back({pair.first, pair.second});
		}
	}

	context.stack.push(pairs);
}
