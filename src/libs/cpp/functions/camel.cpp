#include "camel.hpp"
#include <algorithm>

void camel(Context &context) noexcept
{
	auto str = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	// Capitalize first letter
	str[0] = std::toupper(str[0]);

	// Lowercase the rest
	std::transform(str.begin() + 1, str.end(), str.begin() + 1, ::tolower);

	context.stack.push(str);
}
