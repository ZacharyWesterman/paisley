#include "ceil.hpp"
#include <cmath>

void ceil(Context &context) noexcept
{
	auto params = context.stack.pop().to_array();
	auto value = params[0].to_number();

	context.stack.push(std::ceil(value));
}
