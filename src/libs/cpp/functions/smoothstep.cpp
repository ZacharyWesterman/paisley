#include "smoothstep.hpp"

void smoothstep(Context &context) noexcept
{
	// Smoothstep interpolation between two values.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	double x = params[0].to_number();
	double min = params[1].to_number();
	double max = params[2].to_number();

	const double range = max - min;
	double value = (std::min(std::max(min, x), max) - min) / range;
	value = value * value * (3 - 2 * value);

	context.stack.push(value * range + min);
}
