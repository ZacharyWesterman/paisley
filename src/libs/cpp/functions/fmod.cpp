#include "fmod.hpp"

void fmod(Context &context) noexcept
{
	// Return the floating point remainder of x / y (x mod y).
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	double x = params[0].to_number();
	double y = params[1].to_number();

	double intpart;
	double fracpart = std::modf(x, &intpart);

	double result = std::floor(x / y) + fracpart;
	context.stack.push(result);
}
