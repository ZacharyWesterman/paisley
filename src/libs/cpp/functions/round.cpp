#include "round.hpp"
#include <cmath>

void round(Stack &stack) noexcept
{
	auto params = stack.pop().to_array();
	auto value = params[0].to_number();

	stack.push(std::round(value));
}
