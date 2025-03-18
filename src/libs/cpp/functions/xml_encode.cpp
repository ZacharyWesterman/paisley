#include "xml_encode.hpp"
#include <algorithm>

Value get(const std::map<std::string, Value> &map, const std::string &key)
{
	auto iter = map.find(key);
	if (iter == map.end())
	{
		return Value();
	}
	return iter->second;
}

std::string replace(std::string str, std::string from, std::string to)
{
	size_t start_pos = 0;
	while ((start_pos = str.find(from, start_pos)) != std::string::npos)
	{
		str.replace(start_pos, from.length(), to);
		start_pos += to.length();
	}
	return str;
}

const std::vector<std::string> no_end_tag = {
	"area",
	"base",
	"br",
	"col",
	"command",
	"embed",
	"hr",
	"img",
	"input",
	"keygen",
	"link",
	"meta",
	"param",
	"source",
	"track",
	"wbr"};

std::string stringify_recursive(const Value &obj, int indent)
{
	std::string str = std::string(indent, ' ');

	if (!std::holds_alternative<std::map<std::string, Value>>(obj))
	{
		return str + obj.to_string();
	}

	const auto &t = std::get<std::map<std::string, Value>>(obj);
	const auto type = get(t, "type").to_string();

	if (type == "text")
	{
		auto value = get(t, "value").to_string();

		// Replace xml entities
		value = replace(value, "&", "&amp;");
		value = replace(value, "<", "&lt;");
		value = replace(value, ">", "&gt;");
		value = replace(value, "\"", "&quot;");
		value = replace(value, "'", "&apos;");
		value = replace(value, " ", "&nbsp;");

		return str + value;
	}

	const auto attributes = get(t, "attributes").to_object();

	str += "<" + type;
	for (const auto &pair : attributes)
	{
		str += " " + pair.first + "=\"" + pair.second.to_string() + "\"";
	}
	for (const auto &pair : t)
	{
		if (pair.first != "type" && pair.first != "attributes" && pair.first != "children")
		{
			str += " " + pair.first + "=\"" + pair.second.to_string() + "\"";
		}
	}

	if (std::find(no_end_tag.begin(), no_end_tag.end(), type) != no_end_tag.end())
	{
		return str + "/>";
	}

	str += ">";

	const auto children = get(t, "children").to_array();

	if (children.size() > 0)
	{
		for (const auto &child : children)
		{
			str += "\n" + std::string(indent + 2, ' ');
			str += stringify_recursive(child, indent + 2);
		}
		if (children.size() > 0)
		{
			str += "\n" + std::string(indent, ' ');
		}
	}

	str += "</" + type + ">";

	return str;
}

void xml_encode(Context &context) noexcept
{
	auto ast = context.stack.pop().to_array();

	std::string result = "";
	bool first = true;
	for (const auto &node : ast)
	{
		if (!first)
		{
			result += "\n";
		}
		first = false;
		result += stringify_recursive(node, 0);
	}

	context.stack.push(result);
}
