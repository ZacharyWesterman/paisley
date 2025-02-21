#include "matches.hpp"
#include "../match.hpp"

void matches(Context &context) noexcept
{
	// Check if a string matches a pattern
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	auto str = params[0].to_string();
	auto pattern = params[1].to_string();

	auto value = lua_match(str, pattern);

	// Convert matches to an array of values
	std::vector<Value> values;
	values.reserve(value.size());

	for (const auto &v : value)
	{
		values.push_back(v);
	}

	context.stack.push(values);
}
