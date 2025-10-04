#include "file_write.hpp"

#include <fstream>

void file_write(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto path = params[0].to_string();
	auto content = params[1].to_string();

	std::ofstream file(path);
	if (!file)
	{
		context.stack.push(false);
		return;
	}

	file << content;
	context.stack.push(true);
}
