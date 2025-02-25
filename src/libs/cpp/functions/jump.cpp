#include "jump.hpp"

void jump(Context &context) noexcept
{
	if (context.arg)
	{
		context.instruction_index = context.arg;
	}
	else
	{
		context.instruction_index = context.stack.pop().to_number();
	}
}
