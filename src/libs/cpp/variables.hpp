#pragma once

#include <map>
#include <string>

#include "value.hpp"

struct Variables : public std::map<std::string, Value>
{
	using std::map<std::string, Value>::map;

	Value get(const std::string &key) const noexcept;
	void set(const std::string &key, const Value &value) noexcept;

	bool has(const std::string &key) const noexcept;

	Value &get_ref(const std::string &key);
};
