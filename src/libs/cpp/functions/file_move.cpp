#include "file_move.hpp"

#include <sys/stat.h>

void file_move(Context &context) noexcept
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

	context.stack.push(rename(source.c_str(), destination.c_str()) == 0);
}
