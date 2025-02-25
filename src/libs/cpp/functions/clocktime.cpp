#include "clocktime.hpp"

void clocktime(Context &context) noexcept
{
	// Convert a "seconds since midnight" timestamp into (hour, min, sec, milli)
	const auto timestamp = std::get<std::vector<Value>>(context.stack.pop())[0].to_number();
	const int seconds = timestamp;

	context.stack.push({
		seconds / 3600,
		seconds / 60 % 60,
		seconds % 60,
		(timestamp - std::floor(timestamp)) * 1000,
	});
}
