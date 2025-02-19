#include "jumpiffalse.hpp"

void jumpiffalse(Context &context) noexcept
{
	const Value &top = context.stack[context.stack.size() - 1];
	if (!top.to_bool())
	{
		context.instruction_index = context.arg.x;
	}
}
