#include "json_encode.hpp"

std::string escape_string(const std::string &str) noexcept
{
	std::string escaped;

	size_t pos = 0;
	size_t last = 0;

	while ((pos = str.find("\\", pos)) != std::string::npos)
	{
		escaped += str.substr(0, pos);
		escaped += "\\\\";
		last = pos;
	}

	while ((pos = str.find("\"", pos)) != std::string::npos)
	{
		escaped += str.substr(0, pos);
		escaped += "\\\"";
		last = pos;
	}

	escaped += str.substr(last);

	return escaped;
}

std::string json_indent(int indent) noexcept
{
	std::string json;
	json.reserve(indent * 2);

	for (int i = 0; i < indent; i++)
	{
		json += "  ";
	}

	return json;
}

std::string json_encode_recursive(Value &data, bool pretty = false, int indent = 0) noexcept
{
	std::string json;

	if (std::holds_alternative<std::vector<Value>>(data))
	{
		auto array = std::get<std::vector<Value>>(data);

		json += "[";

		if (pretty)
		{
			json += "\n";
		}

		for (size_t i = 0; i < array.size(); i++)
		{
			if (pretty)
			{
				json += json_indent(indent + 1);
			}
			json += json_encode_recursive(array[i], pretty, indent + 1);
			if (i < array.size() - 1)
			{
				json += ",";
			}
			if (pretty)
			{
				json += "\n";
			}
		}

		if (pretty)
		{
			json += json_indent(indent);
		}
		json += "]";
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(data))
	{
		auto object = std::get<std::map<std::string, Value>>(data);

		json += "{";

		if (pretty)
		{
			json += "\n";
		}

		size_t i = 0;
		for (auto &pair : object)
		{
			if (pretty)
			{
				json += json_indent(indent + 1);
			}
			json += "\"" + escape_string(pair.first) + "\":";
			if (pretty)
			{
				json += " ";
			}
			json += json_encode_recursive(pair.second, pretty, indent + 1);

			if (i < object.size() - 1)
			{
				json += ",";
			}
			if (pretty)
			{
				json += "\n";
			}

			i++;
		}

		if (pretty)
		{
			json += json_indent(indent);
		}
		json += "}";
	}
	else if (std::holds_alternative<std::string>(data))
	{
		json += "\"" + escape_string(std::get<std::string>(data)) + "\"";
	}
	else if (std::holds_alternative<double>(data))
	{
		json += data.to_string();
	}
	else if (std::holds_alternative<bool>(data))
	{
		json += std::get<bool>(data) ? "true" : "false";
	}
	else
	{
		json += "null";
	}

	return json;
}

void json_encode(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto data = params[0];
	auto pretty = params.size() > 1 ? params[1].to_bool() : false;

	context.stack.push(json_encode_recursive(data, pretty));
}
