#include "uuid.hpp"

#include <sstream>
#include <iomanip>

static std::uniform_int_distribution<> dis(0, 15);
static std::uniform_int_distribution<> dis2(8, 11);

void uuid(Context &context) noexcept
{
	context.stack.pop_back(); // Pop the params (always empty)

	// Generate a new UUID
	std::stringstream ss;
	int i;
	ss << std::hex;
	for (i = 0; i < 8; i++)
	{
		ss << dis(context.rng);
	}
	ss << "-";
	for (i = 0; i < 4; i++)
	{
		ss << dis(context.rng);
	}
	ss << "-4";
	for (i = 0; i < 3; i++)
	{
		ss << dis(context.rng);
	}
	ss << "-";
	ss << dis2(context.rng);
	for (i = 0; i < 3; i++)
	{
		ss << dis(context.rng);
	}
	ss << "-";
	for (i = 0; i < 12; i++)
	{
		ss << dis(context.rng);
	};

	context.stack.push(ss.str());
}
