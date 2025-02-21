#include "json_valid.hpp"

// Decode a JSON string into a Value
bool json_validate_recursive(std::string::const_iterator &it, const std::string::const_iterator &end)
{
	// Skip whitespace
	while (it != end && (*it == ' ' || *it == '\t' || *it == '\n' || *it == '\r'))
	{
		it++;
	}

	if (it == end)
	{
		return false;
	}

	// Parse strings
	if (*it == '"')
	{
		bool escape = false;
		for (it++; it != end; it++)
		{
			if (escape)
			{
				unsigned int codepoint = 0;

				switch (*it)
				{
				case '"':
				case '\\':
				case '/':
				case 'b':
				case 'f':
				case 'n':
				case 'r':
				case 't':
					break;
				case 'u':
					// Unicode escape
					if (std::distance(it, end) < 5)
					{
						return false;
					}

					// Skip the 'u'
					it++;

					// Parse the hex digits
					for (int i = 0; i < 4; i++)
					{
						char c = *it;
						if (c >= '0' && c <= '9')
						{
							codepoint = codepoint * 16 + (c - '0');
						}
						else if (c >= 'a' && c <= 'f')
						{
							codepoint = codepoint * 16 + (c - 'a' + 10);
						}
						else if (c >= 'A' && c <= 'F')
						{
							codepoint = codepoint * 16 + (c - 'A' + 10);
						}
						else
						{
							return false;
						}

						it++;
					}

					// Skip back one character
					it--;
					break;
				default:
					return false;
				}

				escape = false;
				continue;
			} // if (escape)

			if (*it == '\\')
			{
				escape = true;
				continue;
			}

			if (*it == '"')
			{
				it++;
				return true;
			}
		} // for (it)

		return false;
	} // if (*it == '"')

	// Parse numbers
	if (*it == '-' || (*it >= '0' && *it <= '9'))
	{
		for (++it; it != end; it++)
		{
			if (*it >= '0' && *it <= '9')
			{
				continue;
			}

			if (*it == '.')
			{
				for (it++; it != end; it++)
				{
					if (*it >= '0' && *it <= '9')
					{
						continue;
					}

					break;
				}
			}

			if (*it == 'e' || *it == 'E')
			{
				for (it++; it != end; it++)
				{
					if (*it == '+' || *it == '-')
					{
						continue;
					}

					if (*it >= '0' && *it <= '9')
					{
						continue;
					}

					break;
				}
			}

			it--;
			break;
		}

		return true;
	}

	// Parse objects
	if (*it == '{')
	{
		for (++it; it != end; it++)
		{
			if (*it == ' ' || *it == '\t' || *it == '\n' || *it == '\r')
			{
				continue;
			}

			if (*it == '}')
			{
				return true;
			}

			if (*it == ',')
			{
				continue;
			}

			if (*it == '"')
			{
				auto key = json_validate_recursive(it, end);
				if (!key)
				{
					return false;
				}

				if (it == end)
				{
					return false;
				}

				if (*it != ':')
				{
					return false;
				}

				it++;
				auto value = json_validate_recursive(it, end);
				if (!value)
				{
					return false;
				}
				continue;
			}

			return false;
		}

		return false;
	}

	// Parse arrays
	if (*it == '[')
	{
		for (++it; it != end; it++)
		{
			if (*it == ' ' || *it == '\t' || *it == '\n' || *it == '\r')
			{
				continue;
			}

			if (*it == ']')
			{
				return true;
			}

			if (*it == ',')
			{
				continue;
			}

			auto value = json_validate_recursive(it, end);
			if (!value)
			{
				return false;
			}
		}

		return false;
	}

	// Parse true
	if (std::string_view(&*it, 4) == "true")
	{
		it += 4;
		return true;
	}

	// Parse false
	if (std::string_view(&*it, 5) == "false")
	{
		it += 5;
		return true;
	}

	// Parse null
	if (std::string_view(&*it, 4) == "null")
	{
		it += 4;
		return true;
	}

	return false;
}

void json_valid(Context &context) noexcept
{
	auto json = std::get<std::vector<Value>>(context.stack.pop())[0];

	if (!std::holds_alternative<std::string>(json))
	{
		context.stack.push(false);
		return;
	}

	const std::string &json_str = std::get<std::string>(json);
	std::string::const_iterator it = json_str.begin();
	bool valid = json_validate_recursive(it, json_str.end());

	context.stack.push(valid);
}
