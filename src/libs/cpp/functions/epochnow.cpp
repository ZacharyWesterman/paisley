#include "epochnow.hpp"
#include <ctime>

void epochnow(Context &context) noexcept
{
	context.stack.pop();
	context.stack.push(time(nullptr));
}
