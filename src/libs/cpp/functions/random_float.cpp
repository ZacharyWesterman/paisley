#include "random_float.hpp"

void random_float(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	double max = params[0].to_number();
	double min = params[1].to_number();

	auto value = context.rng() / (context.rng.max() + 1.0) * (max - min) + min;
	context.stack.push(value);
}
