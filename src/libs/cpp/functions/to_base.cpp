#include "to_base.hpp"
#include <sstream>

void to_base(Context &context) noexcept
{
	// Convert a number to a string of any base.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	double number = params[0].to_number();
	int base = params[1].to_number();
	int pad_width = params[2].to_number();

	std::string result;

	if (base < 2 || base > 36)
	{
		context.warn("Base must be between 2 and 36.");
		context.stack.push("");
		return;
	}

	if (base == 10)
	{
		std::stringstream ss;
		ss << number;
		result = ss.str();
	}
	else
	{
		double fractional = std::fmod(number, 1);
		long integer = static_cast<long>(number);

		std::string digits = "0123456789abcdefghijklmnopqrstuvwxyz";
		bool negative = number < 0;
		if (negative)
		{
			number = -number;
		}

		// Integer part
		do
		{
			result = digits[integer % base] + result;
			integer /= base;
		} while (integer > 0);

		// Fractional part
		if (fractional > 0.0000001)
		{
			result += ".";
			for (int i = 0; i < 10; i++)
			{
				fractional *= base;
				result += digits[static_cast<int>(std::floor(fractional))];
				fractional = std::fmod(fractional, 1);
				if (fractional < 0.0000001)
				{
					break;
				}
			}
		}

		if (negative)
		{
			result = "-" + result;
		}
	}

	if (pad_width > (int)result.length())
	{
		result = std::string(pad_width - result.length(), '0') + result;
	}

	context.stack.push(result);
}
