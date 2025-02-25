#include "type.hpp"

void type(Context &context) noexcept
{
	auto data = std::get<std::vector<Value>>(context.stack.pop())[0];

	if (std::holds_alternative<std::string>(data))
	{
		context.stack.push("string");
	}
	else if (std::holds_alternative<double>(data))
	{
		context.stack.push("number");
	}
	else if (std::holds_alternative<bool>(data))
	{
		context.stack.push("boolean");
	}
	else if (std::holds_alternative<std::vector<Value>>(data))
	{
		context.stack.push("array");
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(data))
	{
		context.stack.push("object");
	}
	else
	{
		context.stack.push("null");
	}
}
