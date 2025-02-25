#include "get_cache_else_jump.hpp"

void get_cache_else_jump(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];

	// Get the cache key
	Value params = vm.return_indices.size() ? vm.return_indices.back().params : std::vector<Value>();

	// If the cache for this subroutine does not exist, jump to the specified index.
	if (vm.cache.find(instruction.operand[0]) == vm.cache.end())
	{
		vm.instruction_index = instruction.operand[1] - 1;
		return;
	}

	const auto &cache = vm.cache[instruction.operand[0]];
	const auto key = params.pretty_print();

	// If the cache for these specific parameters does not exist, jump to the specified index.
	if (cache.find(key) == cache.end())
	{
		vm.instruction_index = instruction.operand[1] - 1;
		return;
	}

	// Otherwise, push the cached value to the stack.
	vm.stack.push(cache.at(key));
}
