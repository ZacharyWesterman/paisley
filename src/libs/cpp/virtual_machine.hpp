#pragma once

#include "stack.hpp"
#include "variables.hpp"
#include "instruction.hpp"
#include <random>
#include <vector>

struct VirtualMachine
{
	Stack stack;
	Variables variables;
	std::mt19937_64 rng;
	size_t instruction_index;
	std::vector<Instruction> instructions;
	std::vector<Value> const_lookup;

	void error(const std::string &message) const noexcept;
	Value &get_const(size_t id) noexcept;
};
