#include "floor.hpp"
#include <cmath>

void floor(Stack &stack) noexcept
{
	auto params = stack.pop().to_array();
	auto value = params[0].to_number();

	stack.push(std::floor(value));
}
