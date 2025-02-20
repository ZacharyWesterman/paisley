#include "ceil.hpp"
#include <cmath>

void ceil(Context &context) noexcept
{
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0].to_number();
	context.stack.push(std::ceil(value));
}
