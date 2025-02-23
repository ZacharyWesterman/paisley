#include "push_index.hpp"

void push_index(VirtualMachine &vm) noexcept
{
	vm.return_indices.push_back({
		vm.instruction_index,
		vm.stack.size(),
		vm.stack.back(),
	});
}
