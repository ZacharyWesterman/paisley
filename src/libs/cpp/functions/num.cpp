#include "num.hpp"

void num(Context &context) noexcept
{
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0];
	context.stack.push(value.to_number());
}
