#include "value.hpp"
#include <sstream>

bool Value::to_bool() const noexcept
{
	// Empty strings, empty arrays, empty objects, and null are false
	if (std::holds_alternative<std::string>(*this))
	{
		return !std::get<std::string>(*this).empty();
	}
	else if (std::holds_alternative<std::vector<Value>>(*this))
	{
		return !std::get<std::vector<Value>>(*this).empty();
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(*this))
	{
		return !std::get<std::map<std::string, Value>>(*this).empty();
	}
	// Numbers are false if they are 0
	else if (std::holds_alternative<double>(*this))
	{
		return std::get<double>(*this) != 0;
	}
	// Booleans are just themselves
	else if (std::holds_alternative<bool>(*this))
	{
		return std::get<bool>(*this);
	}

	return false;
}

double Value::to_number() const noexcept
{
	if (std::holds_alternative<double>(*this))
	{
		return std::get<double>(*this);
	}
	else if (std::holds_alternative<std::string>(*this))
	{
		return std::stod(std::get<std::string>(*this));
	}
	else if (std::holds_alternative<bool>(*this))
	{
		return std::get<bool>(*this);
	}

	// Empty arrays, empty objects, and null are all 0 (incompatible types)
	return 0;
}

std::string Value::to_string() const noexcept
{
	if (std::holds_alternative<std::string>(*this))
	{
		return std::get<std::string>(*this);
	}
	else if (std::holds_alternative<double>(*this))
	{
		return std::to_string(std::get<double>(*this));
	}
	else if (std::holds_alternative<bool>(*this))
	{
		return std::get<bool>(*this) ? "1" : "0";
	}
	// Arrays get converted to a space-delimited string
	else if (std::holds_alternative<std::vector<Value>>(*this))
	{
		std::string result;
		bool first = true;
		for (const Value &value : std::get<std::vector<Value>>(*this))
		{
			if (!first)
			{
				result += " ";
			}
			result += value.to_string();
		}
		return result;
	}
	// Objects get converted to a space-delimited key-value pair string
	else if (std::holds_alternative<std::map<std::string, Value>>(*this))
	{
		std::string result;
		bool first = true;
		for (const auto &pair : std::get<std::map<std::string, Value>>(*this))
		{
			if (!first)
			{
				result += " ";
			}
			result += pair.first + " " + pair.second.to_string();
		}
		return result;
	}

	// null is an empty string.
	return "";
}

std::vector<Value> Value::to_array() const noexcept
{
	if (std::holds_alternative<std::map<std::string, Value>>(*this))
	{
		std::vector<Value> result;
		for (const auto &pair : std::get<std::map<std::string, Value>>(*this))
		{
			result.push_back(pair.first);
			result.push_back(pair.second);
		}
		return result;
	}
	else if (std::holds_alternative<std::vector<Value>>(*this))
	{
		return std::get<std::vector<Value>>(*this);
	}
	else if (std::holds_alternative<std::string>(*this))
	{
		return {std::get<std::string>(*this)};
	}
	else if (std::holds_alternative<double>(*this))
	{
		return {std::get<double>(*this)};
	}
	else if (std::holds_alternative<bool>(*this))
	{
		return {std::get<bool>(*this)};
	}

	// null is an empty array
	return {};
}

std::vector<std::string> Value::to_string_array() const noexcept
{
	std::vector<std::string> result;
	for (const Value &value : to_array())
	{
		result.push_back(value.to_string());
	}
	return result;
}

std::string Value::pretty_print() const noexcept
{
	if (std::holds_alternative<std::string>(*this))
	{
		return '"' + std::get<std::string>(*this) + '"';
	}
	else if (std::holds_alternative<double>(*this))
	{
		std::stringstream ss;
		ss << std::get<double>(*this);
		return ss.str();
	}
	else if (std::holds_alternative<bool>(*this))
	{
		return std::get<bool>(*this) ? "true" : "false";
	}
	else if (std::holds_alternative<std::vector<Value>>(*this))
	{
		std::string result = "[";
		bool first = true;
		for (const Value &value : std::get<std::vector<Value>>(*this))
		{
			if (!first)
			{
				result += ", ";
			}
			result += value.pretty_print();
			first = false;
		}
		result += "]";
		return result;
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(*this))
	{
		std::string result = "{";
		bool first = true;
		for (const auto &pair : std::get<std::map<std::string, Value>>(*this))
		{
			if (!first)
			{
				result += ", ";
			}
			result += pair.first + ": " + pair.second.pretty_print();
			first = false;
		}
		result += "}";
		return result;
	}

	return "null";
}
