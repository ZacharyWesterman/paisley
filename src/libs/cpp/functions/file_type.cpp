#include "file_type.hpp"

#include <sys/stat.h>

void file_type(Context &context) noexcept
{
	auto path = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	struct stat info;
	if (stat(path.c_str(), &info) != 0)
	{
		context.stack.push(Value());
	}
	else if (S_ISREG(info.st_mode))
	{
		context.stack.push("file");
	}
	else if (S_ISDIR(info.st_mode))
	{
		context.stack.push("directory");
	}
	else
	{
		context.stack.push("other");
	}
}
