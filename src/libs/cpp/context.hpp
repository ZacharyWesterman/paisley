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
};
