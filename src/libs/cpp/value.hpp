#pragma once

#include <variant>
#include <string>
#include <vector>
#include <map>

class Null
{
};

class Value : public std::variant<Null, bool, double, std::string, std::vector<Value>, std::map<std::string, Value>>
{
public:
	using std::variant<Null, bool, double, std::string, std::vector<Value>, std::map<std::string, Value>>::variant;

	Value(int value) noexcept : std::variant<Null, bool, double, std::string, std::vector<Value>, std::map<std::string, Value>>(static_cast<double>(value)) {}
	Value(std::initializer_list<Value> values) noexcept : std::variant<Null, bool, double, std::string, std::vector<Value>, std::map<std::string, Value>>(std::vector<Value>(values)) {}

	bool to_bool() const noexcept;
	double to_number() const noexcept;
	std::string to_string() const noexcept;
	std::vector<Value> to_array() const noexcept;

	std::vector<std::string> to_string_array() const noexcept;

	std::string pretty_print() const noexcept;
};
