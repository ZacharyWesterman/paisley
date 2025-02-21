#include "lpad.hpp"

void lpad(Context &context) noexcept
{
	// Left pad a string
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	auto str = params[0].to_string();
	auto pad = params[1].to_string();
	size_t len = params[2].to_number();

	if (str.size() >= len)
	{
		context.stack.push(str);
		return;
	}

	context.stack.push(std::string(len - str.size(), pad[0]) + str);
}
