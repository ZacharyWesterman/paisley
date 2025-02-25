#include "strlike.hpp"
#include "../match.hpp"

void strlike(Context &context) noexcept
{
	auto pattern = context.stack.pop().to_string();
	auto data = context.stack.pop().to_string();

	auto values = lua_match(data, pattern);
	context.stack.push(values.size() > 0);
}
