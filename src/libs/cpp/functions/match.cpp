#include "match.hpp"
#include "../match.hpp"

void match(Context &context) noexcept
{
	// Check if a string matches a pattern
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	auto str = params[0].to_string();
	auto pattern = params[1].to_string();

	auto value = lua_match(str, pattern);

	if (value.empty())
	{
		context.stack.push(Value());
		return;
	}

	context.stack.push(value[0]);
}
