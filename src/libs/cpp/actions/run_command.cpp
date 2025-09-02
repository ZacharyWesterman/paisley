#include "run_command.hpp"

#include <iostream>
#include <chrono>
#include <ctime>
#include <sys/types.h>
#include <thread>
#include <unistd.h>

int LAST_COMMAND_RESULT = 0;
std::string LAST_COMMAND_STDOUT;
std::string LAST_COMMAND_STDERR;
const char RAW_SH_TEXT_SENTINEL = 255;

void run_command(VirtualMachine &vm)
{
	const auto &value = vm.stack.pop().to_string_array();
	const auto &command = value[0];

	if (command == "print" || command == "stdout" || command == "stderr")
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

		auto &stream = (command == "stderr") ? std::cerr : std::cout;
		stream << msg;
		if (command == "print")
		{
			stream << std::endl;
		}

		vm.last_cmd_result = Null();
	}
	else if (command == "stdin")
	{
		std::string line;
		std::getline(std::cin, line);
		vm.last_cmd_result = line;
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
	else if (command == "time" || command == "systime" || command == "sysdate")
	{
		auto t = std::time(nullptr);
		std::tm now = *std::localtime(&t);

		if (command == "sysdate")
		{
			// Output [day, month, year]
			vm.last_cmd_result = {now.tm_mday, now.tm_mon + 1, now.tm_year + 1900};
		}
		else
		{
			// Output seconds since midnight
			vm.last_cmd_result = now.tm_hour * 3600 + now.tm_min * 60 + now.tm_sec;
		}
	}
	else if (command == "sleep")
	{
		std::this_thread::sleep_for(std::chrono::milliseconds((int)(std::stod(value[1]) * 1000.0)));
		vm.last_cmd_result = Null();
	}
	else if (command == "clear")
	{
		// Run clear command
		std::cout << "\033[2J\033[1;1H";
		vm.last_cmd_result = Null();
	}
	else if (command == "!" || command == "?" || command == "?!" || command == "=")
	{
		// Run an arbitrary command

		// Get the arguments
		std::vector<const char *> args;
		for (int i = 1; i < value.size(); ++i)
		{
			args.push_back(value[i].c_str());
		}

		pid_t pid = -1;
		int fd[2];
		if (pipe(fd) == -1)
		{
		}

		// Run the command
		// if (system(cmd) == 0)
		{
			vm.last_cmd_result = Null();
		}
		// else
		{
			vm.error("Failed to run command: " + command);
		}
	}
	else
	{
		vm.error("Unknown command: " + command);
	}
}
