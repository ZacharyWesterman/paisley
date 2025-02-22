#include "endswith.hpp"

void endswith(Context &context) noexcept
{
	// Check if a string ends with another string.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	const auto &str = params[0].to_string();
	const auto &substr = params[1].to_string();

	const auto len = str.length() - substr.length();
	context.stack.push(substr.length() <= str.length() && str.find(substr, len) == len);
}
