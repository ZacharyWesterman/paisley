#include "jump.hpp"

void jump(Context &context) noexcept
{
	context.instruction_index = context.arg.x;
}
