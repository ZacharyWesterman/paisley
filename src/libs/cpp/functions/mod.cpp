#include "mod.hpp"

void mod(Context &context) noexcept
{
	auto b = context.stack.pop().to_number();
	auto a = context.stack.pop().to_number();

	// Safely get modulus. If b is 0, return 0.
	auto result = (b == 0) ? 0 : (long)a % (long)b;
	context.stack.push(result);
}
