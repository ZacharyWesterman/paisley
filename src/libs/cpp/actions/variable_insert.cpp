#include "variable_insert.hpp"

void update_subobject(Value &object, const Value &value, const std::vector<Value> &indices, int i) noexcept
{
	if (i == (long)indices.size() - 1)
	{
		if (std::holds_alternative<std::vector<Value>>(object))
		{
			auto &vec = std::get<std::vector<Value>>(object);
			long n_ix = indices[i].to_number() - 1;
			if (n_ix < 0)
			{
				n_ix += vec.size();
			}
			if (n_ix < 0 || n_ix > (long)vec.size())
			{
				// Out of bounds, can't update
				return;
			}
			vec[n_ix] = value;
		}
		else if (std::holds_alternative<std::map<std::string, Value>>(object))
		{
			auto &obj = std::get<std::map<std::string, Value>>(object);
			auto s_ix = indices[i].to_string();
			obj.insert_or_assign(s_ix, value);
		}
		else if (std::holds_alternative<std::string>(object))
		{
			auto &str = std::get<std::string>(object);
			auto n_ix = indices[i].to_number() - 1;
			if (n_ix < 0)
			{
				n_ix += str.size();
			}
			if (n_ix < 0 || n_ix > (long)str.size())
			{
				// Out of bounds, can't update
				return;
			}
			str[n_ix] = value.to_string()[0];
		}

		return;
	}

	// Not at the bottom level yet
	if (std::holds_alternative<std::vector<Value>>(object))
	{
		auto &vec = std::get<std::vector<Value>>(object);
		auto n_ix = indices[i].to_number() - 1;
		if (n_ix < 0)
		{
			n_ix += vec.size();
		}
		if (n_ix < 0 || n_ix >= (long)vec.size())
		{
			// Out of bounds, can't update
			return;
		}
		update_subobject(vec[n_ix], value, indices, i + 1);
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(object))
	{
		auto &obj = std::get<std::map<std::string, Value>>(object);
		auto s_ix = indices[i].to_string();
		if (obj.find(s_ix) == obj.end())
		{
			// Key doesn't exist, can't update
			return;
		}
		update_subobject(obj[s_ix], value, indices, i + 1);
	}
	else
	{
		// Can't index into anything else
		return;
	}
}

void variable_insert(VirtualMachine &vm) noexcept
{
	auto value = vm.stack.pop();
	auto ix = vm.stack.pop();

	// This is guaranteed to be a string by the compiler
	const auto var_name = std::get<std::string>(vm.stack.pop());
	if (!vm.variables.has(var_name))
	{
		// Variable doesn't exist, so we can't insert into it
		vm.warn("Attempted to insert into non-existent variable '" + var_name + "'. Ignoring!");
		return;
	}

	auto &var = vm.variables.get_ref(var_name);

	// Only valid for arrays, objects, or strings
	if (!std::holds_alternative<std::vector<Value>>(var) && !std::holds_alternative<std::map<std::string, Value>>(var) && !std::holds_alternative<std::string>(var))
	{
		vm.warn("Attempted to insert into non-iterable variable '" + var_name + "'. Ignoring!");
		return;
	}

	// If appending
	if (ix.is_null())
	{
		if (std::holds_alternative<std::vector<Value>>(var))
		{
			std::get<std::vector<Value>>(var).push_back(value);
		}
		else if (std::holds_alternative<std::string>(var))
		{
			auto &str = std::get<std::string>(var);
			str += value.to_string();
		}
		else
		{
			vm.warn("Attempted to append to non-array variable '" + var_name + "'. Ignoring!");
		}
		return;
	}

	const auto indices = ix.to_array();
	if (indices.size() == 0)
	{
		// No indices, nothing to do
		return;
	}

	update_subobject(var, value, indices, 0);
}
