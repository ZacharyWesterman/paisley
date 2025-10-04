#include "run_command.hpp"
#include "replace.hpp"

#include <iostream>
#include <chrono>
#include <ctime>
#include <sys/types.h>
#include <thread>
#include <unistd.h>

int LAST_COMMAND_RESULT = 0;
std::string LAST_COMMAND_STDOUT;
std::string LAST_COMMAND_STDERR;
const char RAW_SH_TEXT_SENTINEL = -1;

std::string escape_shell_arg(const std::string &arg)
{
	// Escape special characters for shell
	std::string escaped = replace(
		replace(
			replace(
				replace(
					replace(
						arg, "\\", "\\\\"),
					"\"", "\\\""),
				"$", "\\$"),
			"`", "\\`"),
		"!", "\\!");
#ifdef _WIN32
	escaped = replace(escaped, "\\\"", "`\"");
#endif
	return escaped;
}

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
	else if (!vm.sandboxed && (command == "!" || command == "?" || command == "?!" || command == "="))
	{
		// If command is run with any parameters, treat them as a shell command to execute
		if (value.size() > 1)
		{
			LAST_COMMAND_RESULT = 0;
			LAST_COMMAND_STDOUT.clear();
			LAST_COMMAND_STDERR.clear();

			// Get the arguments
			std::string args;
			for (size_t i = 1; i < value.size(); ++i)
			{
				// If arg starts with RAW_SH_TEXT_SENTINEL, treat it as a raw shell command,
				// and don't escape special characters.
				if (value[i][0] == RAW_SH_TEXT_SENTINEL)
				{
					args += value[i].substr(1) + " ";
				}
				else
				{
					args += "\"" + escape_shell_arg(value[i]) + "\" ";
				}
			}

			char buffer[512];
			FILE *in = popen(args.c_str(), "r");
			if (in)
			{
				while (fgets(buffer, sizeof(buffer), in))
				{
					LAST_COMMAND_STDOUT += buffer;
				}
				LAST_COMMAND_RESULT = pclose(in);
			}

			if (command != "?!")
			{
				if (command != "?")
				{
					std::cout << LAST_COMMAND_STDOUT;
				}
				else if (command != "!")
				{
					std::cerr << LAST_COMMAND_STDERR;
				}
			}
		}

		if (command == "?")
		{
			vm.last_cmd_result = LAST_COMMAND_STDOUT;
		}
		else if (command == "!")
		{
			vm.last_cmd_result = LAST_COMMAND_STDERR;
		}
		else if (command == "?!")
		{
			vm.last_cmd_result = LAST_COMMAND_STDOUT + LAST_COMMAND_STDERR;
		}
		else
		{
			vm.last_cmd_result = LAST_COMMAND_RESULT;
		}
	}
	else if (command == ".")
	{
		// No-op (results are calculated but discarded)
		vm.last_cmd_result = Null();
	}
	else
	{
		vm.error("Unknown command: " + command);
	}
}
