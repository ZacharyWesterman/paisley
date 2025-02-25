#pragma once

#include <random>

#include "stack.hpp"
#include "variables.hpp"

struct Context
{
	Stack &stack;
	Variables &variables;

	// Random number generator
	std::mt19937_64 &rng;

	size_t instruction_index;

	int arg;

	int line_number;

	void warn(const std::string &message) const noexcept;
};
