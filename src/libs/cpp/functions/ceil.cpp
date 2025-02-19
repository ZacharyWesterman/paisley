#include "ceil.hpp"
#include <cmath>

void ceil(Stack &stack) noexcept
{
	auto params = stack.pop().to_array();
	auto value = params[0].to_number();

	stack.push(std::ceil(value));
}
