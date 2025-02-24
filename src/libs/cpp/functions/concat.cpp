#include "concat.hpp"

void concat(Context &context) noexcept
{
	std::string result;

	for (size_t i = context.stack.size() - context.arg; i < context.stack.size(); i++)
	{
		result += context.stack[i].to_string();
	}
	context.stack.resize(context.stack.size() - context.arg);
	context.stack.push(result);
}
