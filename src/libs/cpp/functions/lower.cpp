#include "lower.hpp"
#include <algorithm>

void lower(Context &context) noexcept
{
	auto str = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();
	std::transform(str.begin(), str.end(), str.begin(), ::tolower);
	context.stack.push(str);
}
