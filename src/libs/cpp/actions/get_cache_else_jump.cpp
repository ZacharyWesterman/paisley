#include "get_cache_else_jump.hpp"

void get_cache_else_jump(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];

	// If the cache for this subroutine does not exist, jump to the specified index.
	if (vm.cache.find(instruction.operand[0]) == vm.cache.end())
	{
		vm.instruction_index = instruction.operand[1];
		return;
	}

	// Get the cache key
	Value params = vm.return_indices.size() ? vm.return_indices.back().params : Null();

	// If the cache for these specific parameters does not exist, jump to the specified index.
	const auto &cache = vm.cache[instruction.operand[0]];
	if (cache.find(params) == cache.end())
	{
		vm.instruction_index = instruction.operand[1];
		return;
	}

	// Push the cached value to the stack
	vm.stack.push(cache.at(params));
}
