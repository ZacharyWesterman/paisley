#include "run_command.hpp"

#include <iostream>
#include <chrono>
#include <thread>

void run_command(VirtualMachine &vm)
{
	const auto &value = vm.stack.pop().to_string_array();
	const auto &command = value[0];

	if (command == "print")
	{
		std::string msg;
		for (size_t i = 1; i < value.size(); ++i)
		{
			if (i > 1)
			{
				msg += " ";
			}
			msg += value[i];
		}

		std::cout << msg << std::endl;

		vm.last_cmd_result = Null();
	}
	else if (command == "error")
	{
		std::string msg;
		for (size_t i = 1; i < value.size(); ++i)
		{
			if (i > 1)
			{
				msg += " ";
			}
			msg += value[i];
		}
		vm.last_cmd_result = Null();

		throw std::runtime_error(msg);
	}
	else if (command == "systime")
	{
		vm.last_cmd_result = 1234; // TEMP
	}
	else if (command == "sysdate")
	{
		vm.last_cmd_result = {1, 2, 3}; // TEMP
	}
	else if (command == "sleep")
	{
		std::this_thread::sleep_for(std::chrono::milliseconds((int)(std::stod(value[1]) * 1000.0)));
		vm.last_cmd_result = Null();
	}
	else
	{
		vm.error("Unknown command: " + command);
	}
}
