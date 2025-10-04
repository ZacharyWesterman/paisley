#include "file_append.hpp"

#include <fstream>

void file_append(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto path = params[0].to_string();
	auto content = params[1].to_string();

	std::ofstream file(path, std::ios::app);
	if (!file)
	{
		context.stack.push(false);
		return;
	}

	file << content;
	context.stack.push(true);
}
