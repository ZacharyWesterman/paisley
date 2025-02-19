#include "floor.hpp"
#include <cmath>

void floor(Context &context) noexcept
{
	auto params = context.stack.pop().to_array();
	auto value = params[0].to_number();

	context.stack.push(std::floor(value));
}
