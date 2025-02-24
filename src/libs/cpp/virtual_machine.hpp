#pragma once

#include "stack.hpp"
#include "variables.hpp"
#include "instruction.hpp"
#include <random>
#include <vector>

struct ReturnInfo
{
	size_t index;
	size_t stack_size;
	Value params;
};

struct ExceptStackInfo
{
	size_t goto_index;
	size_t stack_size;
	size_t return_stack_size;
};

struct VirtualMachine
{
	Stack stack;
	Variables variables;
	std::mt19937_64 rng;
	size_t instruction_index;
	std::vector<Instruction> instructions;
	std::vector<Value> const_lookup;

	Value last_cmd_result;
	std::map<size_t, std::map<Value, Value>> cache;
	std::vector<ReturnInfo> return_indices;
	std::vector<ExceptStackInfo> except_stack;

	void error(const std::string &message) const noexcept;
	Value &get_const(size_t id) noexcept;
};
