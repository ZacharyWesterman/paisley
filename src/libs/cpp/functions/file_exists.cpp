#include "file_exists.hpp"

#include <sys/stat.h>

void file_exists(Context &context) noexcept
{
	auto path = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	struct stat buffer;
	bool exists = (stat(path.c_str(), &buffer) == 0);

	context.stack.push(exists);
}
