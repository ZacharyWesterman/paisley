#include "virtual_machine.hpp"
#include <iostream>

void VirtualMachine::error(const std::string &message) const noexcept
{
	std::cerr << "Error: " << message << std::endl;
	exit(1);
}

Value &VirtualMachine::get_const(size_t id) noexcept
{
	if (id >= const_lookup.size())
	{
		error("Invalid constant index");
	}

	return const_lookup[id];
}
