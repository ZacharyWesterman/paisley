#include "variables.hpp"

Value Variables::get(const std::string &key) const noexcept
{
	if (!has(key))
	{
		return Null();
	}
	return at(key);
}

void Variables::set(const std::string &key, const Value &value) noexcept
{
	(*this)[key] = value;
}

bool Variables::has(const std::string &key) const noexcept
{
	return find(key) != end();
}
