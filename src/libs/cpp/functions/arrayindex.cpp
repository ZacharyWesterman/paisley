#include "arrayindex.hpp"

int get_index(const Context &context, const Value &index, int max, bool warn_if_out_of_bounds) noexcept
{
	if (std::holds_alternative<double>(index))
	{
		int i = std::get<double>(index);

		// Negative indices count from the end of the array
		if (i < 0)
		{
			i += context.stack.size();
		}

		if (i > 0 && i <= max)
		{
			return i - 1;
		}

		if (i == 0)
		{
			context.warn("Array indexes start at 1, not 0. Returning null.");
		}
		else if (warn_if_out_of_bounds)
		{
			context.warn("Array index out of bounds. Returning null.");
		}
	}
	else
	{
		context.warn("Array index must be a number");
	}

	return -1;
}

Value get_at_index(const Context &context, const Value &data, const Value &index) noexcept
{
	if (std::holds_alternative<std::vector<Value>>(data))
	{
		const auto &array = std::get<std::vector<Value>>(data);
		const int i = get_index(context, index, array.size(), true);
		if (i >= 0)
		{
			return array[i];
		}
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(data))
	{
		const auto &object = std::get<std::map<std::string, Value>>(data);
		const auto key = index.to_string();
		const auto it = object.find(key);
		if (it != object.end())
		{
			return it->second;
		}
	}
	else if (std::holds_alternative<std::string>(data))
	{
		const std::string &string = std::get<std::string>(data);
		const int i = get_index(context, index, string.size(), false);
		if (i >= 0)
		{
			return std::string(1, string[i]);
		}
		else
		{
			return "";
		}
	}
	return Value();
}

void arrayindex(Context &context) noexcept
{
	auto index = context.stack.pop();
	auto data = context.stack.pop();

	// If index is an array, return an array of the elements at the indices in index.
	if (std::holds_alternative<std::vector<Value>>(index))
	{
		const auto &indices = std::get<std::vector<Value>>(index);

		// If we're indexing a string, then return a string, not an array.
		if (std::holds_alternative<std::string>(data))
		{
			std::string result;
			for (const Value &i : indices)
			{
				result += std::get<std::string>(get_at_index(context, data, i));
			}
			context.stack.push(result);
		}
		else
		{
			std::vector<Value> result;
			for (const Value &i : indices)
			{
				result.push_back(get_at_index(context, data, i));
			}
			context.stack.push(result);
		}
	}
	else
	{
		context.stack.push(get_at_index(context, data, index));
	}
}
