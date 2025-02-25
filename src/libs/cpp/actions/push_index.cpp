#include "push_index.hpp"

void push_index(VirtualMachine &vm) noexcept
{
	vm.return_indices.push_back({
		vm.instruction_index + 1,
		vm.stack.size() - 1,
		vm.stack.back(),
	});
}
