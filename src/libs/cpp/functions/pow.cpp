#include "pow.hpp"

void pow(Context &context) noexcept
{
	auto rhs = context.stack.pop().to_number();
	auto lhs = context.stack.pop().to_number();

	context.stack.push(std::pow(lhs, rhs));
}
