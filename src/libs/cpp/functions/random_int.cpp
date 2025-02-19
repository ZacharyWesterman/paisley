#include "random_int.hpp"

void random_int(Context &context) noexcept
{
	long max = context.stack.pop().to_number();
	long min = context.stack.pop().to_number();

	auto value = context.rng() % (max - min + 1) + min;
	context.stack.push(value);
}
