#include "modf.hpp"

void modf(Context &context) noexcept
{
	// Split a floating point number into its integer and fractional parts.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	double number = params[0].to_number();

	double intpart;
	double fracpart = std::modf(number, &intpart);

	context.stack.push(std::vector<Value>{intpart, fracpart});
}
