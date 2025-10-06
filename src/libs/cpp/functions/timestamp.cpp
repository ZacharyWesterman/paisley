#include "timestamp.hpp"

void timestamp(Context &context) noexcept
{
	// Convert an (hour, min, sec, milli) array into a "seconds since midnight" timestamp.
	const auto array = std::get<std::vector<Value>>(context.stack.pop())[0];

	if (!std::holds_alternative<std::vector<Value>>(array))
	{
		context.stack.push(0.0);
		return;
	}

	const auto vec = std::get<std::vector<Value>>(array);
	const double hours = vec.size() > 0 ? vec[0].to_number() : 0.0;
	const double minutes = vec.size() > 1 ? vec[1].to_number() : 0.0;
	const double seconds = vec.size() > 2 ? vec[2].to_number() : 0.0;
	const double milliseconds = vec.size() > 3 ? vec[3].to_number() : 0.0;

	context.stack.push(hours * 3600 + minutes * 60 + seconds + milliseconds / 1000);
}
