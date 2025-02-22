#include "time.hpp"
#include <sstream>
#include <iomanip>

std::string isotime(int hour, int min, double sec)
{
	std::stringstream ss;
	ss << std::setw(2) << std::setfill('0') << hour << ':' << min << ':' << (int)sec;

	double milli = std::fmod(sec, 1);
	if (milli > 0.000001)
	{
		std::stringstream ss2;
		ss2 << milli;
		ss << '.' << ss2.str().substr(2);
	}
	return ss.str();
}

void time(Context &context) noexcept
{
	// Convert a number or array representation of a time (sefonds since midnight OR [hour, min, sec, milli]) into an ISO compliant time string.

	auto params = std::get<std::vector<Value>>(context.stack.pop());
	std::string result;

	if (std::holds_alternative<std::vector<Value>>(params[0]))
	{
		auto time = std::get<std::vector<Value>>(params[0]);
		if (time.size() >= 3)
		{
			int hour = time[0].to_number();
			int min = time[1].to_number();
			double sec = time[2].to_number() + (time.size() > 3 ? (time[3].to_number() / 1000.0) : 0);
			result = isotime(hour, min, sec);
		}
		else
		{
			context.warn("Time array must have 4 elements: [hour, min, sec, milli].");
			result = "00:00:00";
		}
	}
	else
	{
		double time = params[0].to_number();
		int hour = time / 3600;
		int min = (time - hour * 3600) / 60;
		double sec = time - hour * 3600 - min * 60;
		result = isotime(hour, min, sec);
	}

	context.stack.push(result);
}
