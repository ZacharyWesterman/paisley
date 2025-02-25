#include "equal.hpp"

void equal(Context &context) noexcept
{
	auto rhs = context.stack.pop();
	auto lhs = context.stack.pop();

	context.stack.push(lhs == rhs);
}
