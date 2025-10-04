#include "random_int.hpp"

void random_int(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	long min = params[0].to_number();
	long max = params[1].to_number();

	auto value = context.rng() % (max - min + 1) + min;
	context.stack.push(value);
}
