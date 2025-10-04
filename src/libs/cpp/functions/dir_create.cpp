#include "dir_create.hpp"

#include <sys/stat.h>

bool _dir_create(const std::string &path, bool recursive) noexcept
{
	if (recursive)
	{
		// Create parent directories if they don't exist
		std::string parent = path.substr(0, path.find_last_of('/'));
		if (!parent.empty())
		{
			// Check if parent exists to avoid infinite recursion
			struct stat info;
			if (stat(parent.c_str(), &info) != 0 || !S_ISDIR(info.st_mode))
			{
				if (!_dir_create(parent, recursive))
				{
					return false;
				}
			}
		}
	}

	return mkdir(path.c_str(), 0755) == 0;
}

void dir_create(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto path = params[0].to_string();
	bool recursive = params.size() > 1 ? params[1].to_bool() : false;

	context.stack.push(_dir_create(path, recursive));
}
