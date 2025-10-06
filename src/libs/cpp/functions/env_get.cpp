#include "env_get.hpp"

void env_get(Context &context) noexcept
{
	// Get an environment variable.
	auto name = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	const char *value = std::getenv(name.c_str());
	if (value)
	{
		context.stack.push(std::string(value));
	}
	else
	{
		context.stack.push(Value());
	}
}
