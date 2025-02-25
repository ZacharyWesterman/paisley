#include "context.hpp"
#include <iostream>

void Context::warn(const std::string &message) const noexcept
{
	std::cerr << line_number << ": WARNING: " << message << std::endl;
}
