#include "dir_list.hpp"

#include <filesystem>

void dir_list(Context &context) noexcept
{
	auto path = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	std::vector<Value> files;
	for (const auto &entry : std::filesystem::directory_iterator(path))
	{
		auto filename = entry.path().filename().string();
		files.push_back(filename);
	}

	context.stack.push(files);
}
