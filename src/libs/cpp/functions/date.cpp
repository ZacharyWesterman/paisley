#include "date.hpp"
#include <sstream>
#include <iomanip>

void date(Context &context) noexcept
{
	// Convert an array representation of a date (day, month, year) into an ISO compliant date string.

	auto params = std::get<std::vector<Value>>(context.stack.pop());
	std::string result;

	if (std::holds_alternative<std::vector<Value>>(params[0]))
	{
		auto date = std::get<std::vector<Value>>(params[0]);
		if (date.size() >= 3)
		{
			int day = date[0].to_number();
			int month = date[1].to_number();
			int year = date[2].to_number();

			std::stringstream ss;
			ss << std::setw(4) << std::setfill('0') << year << '-' << std::setw(2) << month << '-' << day;
			result = ss.str();
		}
		else
		{
			context.warn("Date array must have 3 elements: [day, month, year].");
			result = "0000-00-00";
		}
	}
	else
	{
		context.warn("Date requires an array [day, month, year].");
		result = "0000-00-00";
	}

	context.stack.push(result);
}
