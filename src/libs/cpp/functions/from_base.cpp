#include "from_base.hpp"

int from_base(char c) noexcept
{
	if (c >= '0' && c <= '9')
		return c - '0';
	if (c >= 'A' && c <= 'Z')
		return c - 'A' + 10;
	if (c >= 'a' && c <= 'z')
		return c - 'a' + 10;
	return -1;
}

void from_base(Context &context) noexcept
{
	// Convert a string representation of a number in a given base to a floating point number.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	std::string text = params[0].to_string();
	int base = static_cast<int>(params[1].to_number());

	if (base < 2 || base > 36)
	{
		context.warn("In from_base(), base must be between 2 and 36.");
		context.stack.push(0.0);
		return;
	}

	double integer_part = 0.0;
	double fractional_part = 0.0;

	size_t point_index = text.find('.');
	std::string int_text = (point_index == std::string::npos) ? text : text.substr(0, point_index);
	std::string fract_text = (point_index == std::string::npos) ? "" : text.substr(point_index + 1);

	for (char c : int_text)
	{
		int digit = from_base(c);
		integer_part = integer_part * base + digit;
	}

	double place = base;
	for (char c : fract_text)
	{
		double digit = from_base(c);
		fractional_part = fractional_part + digit / place;
		place *= base;
	}

	context.stack.push(integer_part + fractional_part);
}
