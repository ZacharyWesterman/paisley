#include "jumpifnil.hpp"

void jumpifnil(Context &context) noexcept
{
	const Value &top = context.stack.back();

	if (top.is_null()) // Hack to correctly check for null variant
	{
		context.instruction_index = context.arg;
	}
}
