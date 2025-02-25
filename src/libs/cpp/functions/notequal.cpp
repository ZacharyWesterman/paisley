#include "notequal.hpp"

void notequal(Context &context) noexcept
{
	auto rhs = context.stack.pop();
	auto lhs = context.stack.pop();

	context.stack.push(lhs != rhs);
}
