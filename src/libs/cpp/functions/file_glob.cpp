#include "file_glob.hpp"

#include <glob.h>
#include <vector>
#include <string>

void file_glob(Context &context) noexcept
{
	auto pattern = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	glob_t glob_result;
	glob(pattern.c_str(), GLOB_TILDE, nullptr, &glob_result);

	std::vector<Value> files;
	for (size_t i = 0; i < glob_result.gl_pathc; ++i)
	{
		files.push_back(glob_result.gl_pathv[i]);
	}

	globfree(&glob_result);

	context.stack.push(files);
}
