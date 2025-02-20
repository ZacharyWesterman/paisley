#include "upper.hpp"
#include <algorithm>

void upper(Context &context) noexcept
{
	auto str = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();
	std::transform(str.begin(), str.end(), str.begin(), ::toupper);
	context.stack.push(str);
}
