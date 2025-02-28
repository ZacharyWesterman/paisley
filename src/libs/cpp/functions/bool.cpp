#include "bool.hpp"

void _bool(Context &context) noexcept
{
	auto value = context.stack.pop();
	context.stack.push(value.to_bool());
}
