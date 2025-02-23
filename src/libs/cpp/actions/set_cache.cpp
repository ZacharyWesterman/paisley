#include "set_cache.hpp"

void set_cache(VirtualMachine &vm) noexcept
{
	// Set the cache for the current subroutine (does not pop the stack)
	auto &instruction = vm.instructions[vm.instruction_index];

	// Get the cache key
	Value params = vm.return_indices.size() ? vm.return_indices.back().params : Null();

	// Set the cache value
	vm.cache[instruction.operand[0]][params] = vm.stack.back();
}
