#include "file_copy.hpp"

#include <sys/stat.h>
#include <fstream>

void file_copy(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto source = params[0].to_string();
	auto destination = params[1].to_string();
	bool overwrite = params.size() > 2 ? params[2].to_bool() : false;

	if (!overwrite)
	{
		struct stat buffer;
		if (stat(destination.c_str(), &buffer) == 0)
		{
			context.stack.push(false);
			return;
		}
	}

	// Copy file contents
	std::ifstream src(source, std::ios::binary);
	if (!src)
	{
		context.stack.push(false);
		return;
	}

	std::ofstream dest(destination, std::ios::binary);
	if (!dest)
	{
		context.stack.push(false);
		return;
	}

	dest << src.rdbuf();
	context.stack.push(true);
}
