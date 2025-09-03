#include "update.hpp"
#include <iostream>

void update(Context &context) noexcept
{
	// Replace an element in an array or object
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto object = params[0];
	auto indices = params[1];
	auto value = params[2];
	// bool is_string = false;

	// Only valid for arrays, objects, or strings
	if (std::holds_alternative<std::string>(object))
	{
		// is_string = true;
		std::vector<Value> chars;
		for (auto ch : std::get<std::string>(object))
		{
			chars.push_back(std::string(1, ch));
		}
		object = chars;
	}
	else if (!std::holds_alternative<std::vector<Value>>(object) && !std::holds_alternative<std::map<std::string, Value>>(object))
	{
		context.stack.push(object);
		return;
	}

	if (!std::holds_alternative<std::vector<Value>>(indices) && !std::holds_alternative<std::map<std::string, Value>>(indices))
	{
		indices = std::vector<Value>{indices};
	}
	auto indexes = std::get<std::vector<Value>>(indices);
	if (indexes.size() == 0)
	{
		context.stack.push(object);
		return;
	}

	// Narrow down to sub-object
	Value *sub_object = &object;
	for (size_t i = 0; i < indexes.size() - 1; i++)
	{
		auto ix = indexes[i];
		if (std::holds_alternative<std::map<std::string, Value>>(*sub_object))
		{
			auto s_ix = ix.to_string();
			auto obj = std::get_if<std::map<std::string, Value>>(sub_object);
			if (obj->find(s_ix) == obj->end())
			{
				// We can only set the bottom-level object
				context.stack.push(object);
				return;
			}
			sub_object = &(*obj)[s_ix];
		}
		else if (!std::holds_alternative<std::vector<Value>>(*sub_object))
		{
			context.stack.push(object);
			return;
		}
		else
		{
			auto n_ix = ix.to_number() - 1;
			auto vec = std::get_if<std::vector<Value>>(sub_object);
			if (n_ix < 0)
			{
				n_ix += vec->size();
			}
			if (n_ix < 0 || n_ix >= vec->size())
			{
				// We can only set the bottom-level object
				context.stack.push(object);
				return;
			}
			sub_object = &(*vec)[n_ix];
		}
	}

	auto ix = indexes.back();
	if (std::holds_alternative<std::map<std::string, Value>>(*sub_object))
	{
		auto obj = std::get_if<std::map<std::string, Value>>(sub_object);
		auto s_ix = ix.to_string();

		obj->insert_or_assign(s_ix, value);
	}
	else if (std::holds_alternative<std::vector<Value>>(*sub_object))
	{
		auto vec = std::get_if<std::vector<Value>>(sub_object);
		auto n_ix = ix.to_number() - 1;
		if (n_ix < 0)
		{
			n_ix += vec->size();
		}
		if (n_ix < 0)
		{
			// Insert at the beginning
			vec->insert(vec->begin(), value);
		}
		else if (n_ix >= vec->size())
		{
			// Append to the end
			vec->push_back(value);
		}
		else
		{
			(*vec)[n_ix] = value;
		}
	}

	context.stack.push(object);
}
