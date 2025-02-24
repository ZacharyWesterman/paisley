#include "json_decode.hpp"
#include <stdexcept>
#include <string_view>

#include <iostream>

class JsonError : public std::runtime_error
{
public:
	JsonError(const std::string &message, int line_no) : std::runtime_error(std::string("JSON parse error at line ") + std::to_string(line_no) + ": " + message) {}
};

// Decode a JSON string into a Value
Value json_decode_recursive(std::string::const_iterator &it, const std::string::const_iterator &end, int line_no)
{
	// Skip whitespace
	while (it != end && (*it == ' ' || *it == '\t' || *it == '\n' || *it == '\r'))
	{
		it++;
	}

	if (it == end)
	{
		throw JsonError("Unexpected end of input", line_no);
	}

	// Parse strings
	if (*it == '"')
	{
		// String
		std::string str;
		bool escape = false;
		for (it++; it != end; it++)
		{
			if (escape)
			{
				unsigned int codepoint = 0;

				switch (*it)
				{
				case '"':
					str += '"';
					break;
				case '\\':
					str += '\\';
					break;
				case '/':
					str += '/';
					break;
				case 'b':
					str += '\b';
					break;
				case 'f':
					str += '\f';
					break;
				case 'n':
					str += '\n';
					break;
				case 'r':
					str += '\r';
					break;
				case 't':
					str += '\t';
					break;
				case 'u':
					// Unicode escape
					if (std::distance(it, end) < 5)
					{
						throw JsonError("Unexpected end of input", line_no);
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
							throw JsonError("Invalid hex digit in unicode escape", line_no);
						}

						it++;
					}

					// Convert the codepoint to UTF-8
					if (codepoint < 0x80)
					{
						str += codepoint;
					}
					else if (codepoint < 0x800)
					{
						str += 0xC0 | (codepoint >> 6);
						str += 0x80 | (codepoint & 0x3F);
					}
					else if (codepoint < 0x10000)
					{
						str += 0xE0 | (codepoint >> 12);
						str += 0x80 | ((codepoint >> 6) & 0x3F);
						str += 0x80 | (codepoint & 0x3F);
					}
					else
					{
						str += 0xF0 | (codepoint >> 18);
						str += 0x80 | ((codepoint >> 12) & 0x3F);
						str += 0x80 | ((codepoint >> 6) & 0x3F);
						str += 0x80 | (codepoint & 0x3F);
					}

					// Skip back one character
					it--;
					break;
				default:
					throw JsonError("Invalid escape sequence", line_no);
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
				return str;
			}

			str += *it;

		} // for (it)

		throw JsonError("Unterminated string", line_no);

	} // if (*it == '"')

	// Parse numbers
	if (*it == '-' || (*it >= '0' && *it <= '9'))
	{
		// Number
		std::string num;
		num += *it;
		for (++it; it != end; it++)
		{
			if (*it >= '0' && *it <= '9')
			{
				num += *it;
				continue;
			}

			if (*it == '.')
			{
				num += '.';
				for (it++; it != end; it++)
				{
					if (*it >= '0' && *it <= '9')
					{
						num += *it;
						continue;
					}

					break;
				}
			}

			if (*it == 'e' || *it == 'E')
			{
				num += 'e';
				for (it++; it != end; it++)
				{
					if (*it == '+' || *it == '-')
					{
						num += *it;
						continue;
					}

					if (*it >= '0' && *it <= '9')
					{
						num += *it;
						continue;
					}

					break;
				}
			}

			it--;
			break;
		}

		return std::stod(num);
	}

	// Parse objects
	if (*it == '{')
	{
		// Object
		std::map<std::string, Value> object;
		for (++it; it != end; it++)
		{
			if (*it == ' ' || *it == '\t' || *it == '\n' || *it == '\r')
			{
				continue;
			}

			if (*it == '}')
			{
				return object;
			}

			if (*it == ',')
			{
				continue;
			}

			if (*it == '"')
			{
				auto key = json_decode_recursive(it, end, line_no);
				if (!std::holds_alternative<std::string>(key))
				{
					throw JsonError("Object key is not a string", line_no);
				}

				if (it == end)
				{
					throw JsonError("Unexpected end of input", line_no);
				}

				if (*it != ':')
				{
					throw JsonError("Expected ':'", line_no);
				}

				it++;
				auto value = json_decode_recursive(it, end, line_no);
				object[std::get<std::string>(key)] = value;
				continue;
			}

			throw JsonError("Expected object key", line_no);
		}

		throw JsonError("Unterminated object", line_no);
	}

	// Parse arrays
	if (*it == '[')
	{
		// Array
		std::vector<Value> array;
		for (++it; it != end; it++)
		{
			if (*it == ' ' || *it == '\t' || *it == '\n' || *it == '\r')
			{
				continue;
			}

			if (*it == ']')
			{
				return array;
			}

			if (*it == ',')
			{
				continue;
			}

			auto value = json_decode_recursive(it, end, line_no);
			array.push_back(value);
		}

		throw JsonError("Unterminated array", line_no);
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
		return false;
	}

	// Parse null
	if (std::string_view(&*it, 4) == "null")
	{
		it += 4;
		return Null();
	}

	throw JsonError("Unexpected character", line_no);
}

void json_decode(Context &context)
{
	auto json = std::get<std::vector<Value>>(context.stack.pop())[0];

	if (!std::holds_alternative<std::string>(json))
	{
		throw std::runtime_error("Input to json_decode is not a string");
	}

	const std::string &json_str = std::get<std::string>(json);
	std::string::const_iterator it = json_str.begin();
	auto value = json_decode_recursive(it, json_str.end(), context.line_number);

	context.stack.push(value);
}
