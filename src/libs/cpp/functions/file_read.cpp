#include "file_read.hpp"

#include <fstream>

void file_read(Context &context) noexcept
{
	auto path = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	std::ifstream file(path);
	if (!file)
	{
		context.stack.push(Value());
		return;
	}

	std::string content((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
	context.stack.push(content);
}
