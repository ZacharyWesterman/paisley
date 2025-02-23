#include "jumpifnil.hpp"

void jumpifnil(Context &context) noexcept
{
	const Value &top = context.stack[context.stack.size() - 1];
	if (std::holds_alternative<Null>(top))
	{
		context.instruction_index = context.arg;
	}
}
