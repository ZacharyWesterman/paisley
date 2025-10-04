#include "file_stat.hpp"

#include <sys/stat.h>

void file_stat(Context &context) noexcept
{
	auto path = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	struct stat info;
	if (stat(path.c_str(), &info) != 0)
	{
		context.stack.push(Value());
	}
	else
	{
		std::string mode = S_ISDIR(info.st_mode) ? "directory" : (S_ISREG(info.st_mode) ? "file" : "other");
		std::string permissions;
		permissions += (info.st_mode & S_IRUSR ? "r" : "-");
		permissions += (info.st_mode & S_IWUSR ? "w" : "-");
		permissions += (info.st_mode & S_IXUSR ? "x" : "-");
		permissions += (info.st_mode & S_IRGRP ? "r" : "-");
		permissions += (info.st_mode & S_IWGRP ? "w" : "-");
		permissions += (info.st_mode & S_IXGRP ? "x" : "-");
		permissions += (info.st_mode & S_IROTH ? "r" : "-");
		permissions += (info.st_mode & S_IWOTH ? "w" : "-");
		permissions += (info.st_mode & S_IXOTH ? "x" : "-");

		auto object = std::map<std::string, Value>{
			{"gid", static_cast<double>(info.st_gid)},
			{"size", static_cast<double>(info.st_size)},
			{"uid", static_cast<double>(info.st_uid)},
			{"dev", static_cast<double>(info.st_dev)},
			{"mode", mode},
			{"blksize", static_cast<double>(info.st_blksize)},
			{"rdev", static_cast<double>(info.st_rdev)},
			{"access", static_cast<double>(info.st_atime)},
			{"nlink", static_cast<double>(info.st_nlink)},
			{"change", static_cast<double>(info.st_ctime)},
			{"modification", static_cast<double>(info.st_mtime)},
			{"permissions", permissions},
			{"blocks", static_cast<double>(info.st_blocks)},
			{"ino", static_cast<double>(info.st_ino)},
		};
		context.stack.push(object);
	}
}
