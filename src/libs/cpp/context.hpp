#pragma once

#include "stack.hpp"

struct Context
{
	Stack &stack;
	int instruction_index;

	struct
	{
		int x;
		int y;
	} arg;

	int line_number;

	void warn(const std::string &message) const noexcept;
};
