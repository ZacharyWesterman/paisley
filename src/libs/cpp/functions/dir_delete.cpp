#include "dir_delete.hpp"

#include <unistd.h>
#include <filesystem>

bool _dir_delete(const std::string &path, bool recursive) noexcept
{
	if (recursive)
	{
		// Remove all contents in the directory before removing the directory itself
		for (const auto &entry : std::filesystem::directory_iterator(path))
		{
			if (entry.is_directory())
			{
				_dir_delete(entry.path().string(), true);
			}
			else
			{
				std::remove(entry.path().string().c_str());
			}
		}
	}

	return rmdir(path.c_str()) == 0;
}

void dir_delete(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto path = params[0].to_string();
	bool recursive = params.size() > 1 ? params[1].to_bool() : false;
	context.stack.push(_dir_delete(path, recursive));
}
