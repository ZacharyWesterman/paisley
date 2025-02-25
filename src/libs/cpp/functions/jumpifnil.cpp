#include "jumpifnil.hpp"

void jumpifnil(Context &context) noexcept
{
	const Value &top = context.stack.back();

	if (top.index() + 1 < 2) // Hack to correctly check for null variant
	{
		context.instruction_index = context.arg;
	}
}
