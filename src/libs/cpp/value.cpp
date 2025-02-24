#include "value.hpp"
#include <sstream>

bool Value::is_null() const noexcept
{
	return index() + 1 < 2; // Hack to correctly check for null variant
}

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
		try
		{
			return std::stod(std::get<std::string>(*this));
		}
		catch (const std::invalid_argument &)
		{
			return 0;
		}
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
		std::stringstream ss;
		ss << std::get<double>(*this);
		return ss.str();
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
			first = false;
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
			first = false;
		}
		return result;
	}

	// null is an empty string.
	return "";
}

std::vector<Value> Value::to_array() const noexcept
{
	std::vector<Value> result;
	if (std::holds_alternative<std::map<std::string, Value>>(*this))
	{
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
	else if (!std::holds_alternative<Null>(*this))
	{
		result.push_back(*this);
	}

	// null is an empty array
	return result;
}

std::vector<std::string> Value::to_string_array() const noexcept
{
	std::vector<std::string> result;
	for (const Value &value : to_array())
	{
		if (std::holds_alternative<std::vector<Value>>(value))
		{
			for (const auto &sub_value : std::get<std::vector<Value>>(value))
			{
				for (const auto &sub_sub_value : sub_value.to_string_array())
				{
					result.push_back(sub_sub_value);
				}
			}
		}
		else if (std::holds_alternative<std::map<std::string, Value>>(value))
		{
			for (const auto &pair : std::get<std::map<std::string, Value>>(value))
			{
				result.push_back(pair.first);
				for (const auto &sub_value : pair.second.to_string_array())
				{
					result.push_back(sub_value);
				}
			}
		}
		else
		{
			result.push_back(value.to_string());
		}
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

bool Value::operator==(const Value &rhs) const noexcept
{
	if (index() != rhs.index())
	{
		return false;
	}

	if (std::holds_alternative<std::string>(*this))
	{
		return std::get<std::string>(*this) == std::get<std::string>(rhs);
	}
	else if (std::holds_alternative<double>(*this))
	{
		return std::get<double>(*this) == std::get<double>(rhs);
	}
	else if (std::holds_alternative<bool>(*this))
	{
		return std::get<bool>(*this) == std::get<bool>(rhs);
	}
	else if (std::holds_alternative<std::vector<Value>>(*this))
	{
		return std::get<std::vector<Value>>(*this) == std::get<std::vector<Value>>(rhs);
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(*this))
	{
		return std::get<std::map<std::string, Value>>(*this) == std::get<std::map<std::string, Value>>(rhs);
	}

	return true;
}

bool Value::operator!=(const Value &rhs) const noexcept
{
	return !(*this == rhs);
}

void make_comparable(Value &lhs, Value &rhs) noexcept
{
	// Anything that's not a number or a string is cast to a string
	if (!std::holds_alternative<std::string>(lhs) && !std::holds_alternative<double>(lhs))
	{
		lhs = lhs.to_string();
	}
	if (!std::holds_alternative<std::string>(rhs) && !std::holds_alternative<double>(rhs))
	{
		rhs = rhs.to_string();
	}

	// If one of the two is a string, the other is cast to a string
	if (lhs.index() != rhs.index())
	{
		if (std::holds_alternative<std::string>(lhs))
		{
			rhs = rhs.to_string();
		}
		else
		{
			lhs = lhs.to_string();
		}
	}
}

bool Value::operator<(const Value &rhs) const noexcept
{
	// Arrays, objects, and null cannot be compared.
	if (std::holds_alternative<std::vector<Value>>(*this) || std::holds_alternative<std::vector<Value>>(rhs))
	{
		return false;
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(*this) || std::holds_alternative<std::map<std::string, Value>>(rhs))
	{
		return false;
	}
	else if (std::holds_alternative<Null>(*this) || std::holds_alternative<Null>(rhs))
	{
		return false;
	}

	if (std::holds_alternative<std::string>(*this) || std::holds_alternative<std::string>(rhs))
	{
		return to_string() < rhs.to_string();
	}
	return to_number() < rhs.to_number();
}
