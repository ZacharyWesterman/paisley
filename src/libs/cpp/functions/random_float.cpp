#include "random_float.hpp"

void random_float(Context &context) noexcept
{
	double max = context.stack.pop().to_number();
	double min = context.stack.pop().to_number();

	auto value = context.rng() / (context.rng.max() + 1.0) * (max - min) + min;
	context.stack.push(value);
}
