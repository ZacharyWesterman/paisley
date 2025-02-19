#include "boolnot.hpp"

void boolnot(Context &context) noexcept
{
	const auto &value = context.stack.pop();
	context.stack.push(!value.to_bool());
}
