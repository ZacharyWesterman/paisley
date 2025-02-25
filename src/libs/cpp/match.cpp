#include "match.hpp"
#include <regex>

std::regex lua_pattern_to_regex(const std::string &pattern)
{
	std::string re;
	re.reserve(pattern.size() * 2); // Reserve enough space to avoid frequent reallocations

	for (size_t i = 0; i < pattern.size(); ++i)
	{
		char c = pattern[i];
		switch (c)
		{
		case '%':
			if (i + 1 < pattern.size())
			{
				char next = pattern[++i];
				switch (next)
				{
				case 'a':
					re += "[A-Za-z]";
					break;
				case 'c':
					re += "[\\x00-\\x1F\\x7F]";
					break;
				case 'd':
					re += "\\d";
					break;
				case 'g':
					re += "[\\x21-\\x7E]";
					break;
				case 'l':
					re += "[a-z]";
					break;
				case 'p':
					re += "[\\x21-\\x2F\\x3A-\\x40\\x5B-\\x60\\x7B-\\x7E]";
					break;
				case 's':
					re += "\\s";
					break;
				case 'u':
					re += "[A-Z]";
					break;
				case 'w':
					re += "\\w";
					break;
				case 'x':
					re += "[A-Fa-f0-9]";
					break;
				case 'z':
					re += "\\x00";
					break;
				case '%':
					re += "%";
					break;
				default:
					re += "\\" + std::string(1, next);
					break;
				}
			}
			break;
		case '|':
			re += "\\|";
			break;
		case '\\':
			re += "\\\\";
			break;
		default:
			re += c;
			break;
		}
	}

	return std::regex(re);
}

// Match patterns using Lua's pattern matching syntax.
std::vector<std::string> lua_match(const std::string &str, const std::string &pattern)
{
	std::vector<std::string> values;
	auto re = lua_pattern_to_regex(pattern);
	std::smatch match;

	if (std::regex_match(str, match, re))
	{
		values.reserve(match.size());

		for (size_t i = 0; i < match.size(); ++i)
		{
			values.push_back(match[i].str());
		}
	}
	return values;
}
