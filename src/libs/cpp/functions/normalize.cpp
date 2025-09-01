#include "normalize.hpp"
#include <math.h>

void normalize(Context &context) noexcept
{
	auto vector = std::get<std::vector<Value>>(context.stack.pop())[0].to_array();

	double length = 0;
	for (const auto &value : vector)
	{
		length += value.to_number() * value.to_number();
	}
	length = sqrt(length);

	for (auto &value : vector)
	{
		value = value.to_number() / length;
	}

	context.stack.push(vector);
}
