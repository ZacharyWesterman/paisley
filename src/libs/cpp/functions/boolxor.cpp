#include "boolxor.hpp"

void boolxor(Context &context) noexcept
{
	const auto &rhs = context.stack.pop();
	const auto &lhs = context.stack.pop();
	context.stack.push(lhs.to_bool() != rhs.to_bool());
}
