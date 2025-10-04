#include "file_delete.hpp"

void file_delete(Context &context) noexcept
{
	auto path = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();
	context.stack.push(std::remove(path.c_str()) == 0);
}
