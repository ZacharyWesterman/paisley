#include "bool.hpp"

void _bool(Context &context) noexcept
{
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0];
	context.stack.push(value.to_bool());
}
