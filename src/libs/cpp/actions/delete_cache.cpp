#include "delete_cache.hpp"

void delete_cache(VirtualMachine &vm) noexcept
{
	// Delete the cache for the given subroutine
	auto &instruction = vm.instructions[vm.instruction_index];

	vm.cache.erase(instruction.operand[0]);
}
