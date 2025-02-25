#include "beginswith.hpp"

void beginswith(Context &context) noexcept
{
	// Check if a string begins with another string.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	const auto &str = params[0].to_string();
	const auto &substr = params[1].to_string();

	context.stack.push(substr.length() <= str.length() && str.rfind(substr, 0) == 0);
}
