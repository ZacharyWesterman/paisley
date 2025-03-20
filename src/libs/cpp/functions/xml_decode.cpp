#include "xml_decode.hpp"
#include <string>
#include <map>
#include <vector>
#include <regex>
#include <stack>
#include <unordered_map>

#include "../replace.hpp"

// Token types
enum TokenType
{
	TAG_OPEN = 0,
	TAG_CLOSE = 1,
	TAG_TYPE = 3,
	TAG_ATTR = 4,
	TAG_VALUE = 5,
	EQUAL = 6,
	TEXT = 7
};

// Entity structure
struct Entity
{
	std::string type;
	std::string value;
	std::unordered_map<std::string, std::string> attributes;
	std::unordered_map<std::string, std::string> top_attributes;

	std::vector<Entity> children;
	bool open = false;
	bool close = false;
};

// Stack element structure
struct StackElement
{
	int id;
	std::string text;
	std::string value;
};

// XML configuration for no-end tags
std::unordered_map<std::string, bool> no_end_tag = {
	{"br", true},
	{"img", true},
	{"input", true},
	{"meta", true},
	{"link", true},
	{"hr", true},
	{"base", true},
	{"col", true},
	{"embed", true},
	{"param", true},
	{"source", true},
	{"track", true},
	{"wbr", true},
	{"area", true},
	{"keygen", true},
	{"command", true},
};

// Tokenize function
std::function<std::tuple<int, std::string>()> tokenize(std::string text)
{
	bool in_tag = false;
	bool found_tag_type = false;
	int tag_attr_type = TAG_ATTR;

	return [=]() mutable -> std::tuple<int, std::string>
	{
		while (!text.empty())
		{
			if (in_tag)
			{
				// Tag end
				if (text[0] == '>')
				{
					text = text.substr(1);
					in_tag = false;
					return {TAG_CLOSE, ">"};
				}

				// Self-closing tag end
				std::smatch match;
				if (std::regex_search(text, match, std::regex("^/\\s*>")))
				{
					text = text.substr(match.length());
					in_tag = false;
					return {TAG_CLOSE, "/>"};
				}

				if (!found_tag_type)
				{
					// Tag name
					if (std::regex_search(text, match, std::regex("^[^\\s=/>\"]+")))
					{
						std::string m = match.str();
						text = text.substr(m.length());
						found_tag_type = true;
						return {TAG_TYPE, m};
					}
				}
				else
				{
					// Double-quoted attribute value
					if (std::regex_search(text, match, std::regex("^\"[^\"]*\"")))
					{
						std::string m = match.str();
						text = text.substr(m.length());
						int attr_type = tag_attr_type;
						tag_attr_type = TAG_ATTR;
						return {attr_type, m.substr(1, m.length() - 2)};
					}

					// Single-quoted attribute value
					if (std::regex_search(text, match, std::regex("^'[^']*'")))
					{
						std::string m = match.str();
						text = text.substr(m.length());
						int attr_type = tag_attr_type;
						tag_attr_type = TAG_ATTR;
						return {attr_type, m.substr(1, m.length() - 2)};
					}

					// Attribute or attribute value
					if (std::regex_search(text, match, std::regex("^[^\\s=/>\"]+")))
					{
						std::string m = match.str();
						text = text.substr(m.length());
						int attr_type = tag_attr_type;
						tag_attr_type = TAG_ATTR;
						return {attr_type, m};
					}

					// Attribute value marker
					if (text[0] == '=')
					{
						text = text.substr(1);
						tag_attr_type = TAG_VALUE;
						// Ignore the equal sign
					}

					// Slash without closing tag
					if (text[0] == '/')
					{
						text = text.substr(1);
						return {TEXT, "/"};
					}
				}

				// Whitespace
				if (std::regex_search(text, match, std::regex("^\\s+")))
				{
					text = text.substr(match.length());
					// Ignore whitespace
				}
			}
			else
			{
				// Close tag start
				std::smatch match;
				if (std::regex_search(text, match, std::regex("^<\\s*/")))
				{
					text = text.substr(match.length());
					in_tag = true;
					found_tag_type = false;
					tag_attr_type = TAG_ATTR;
					return {TAG_OPEN, "</"};
				}

				// Open tag start
				if (text[0] == '<')
				{
					text = text.substr(1);
					in_tag = true;
					found_tag_type = false;
					tag_attr_type = TAG_ATTR;
					return {TAG_OPEN, "<"};
				}

				// Plain text
				if (std::regex_search(text, match, std::regex("^[^<]+")))
				{
					std::string m = match.str();
					text = text.substr(m.length());

					// Remove leading and trailing whitespace
					m = std::regex_replace(m, std::regex("^\\s+"), "");
					m = std::regex_replace(m, std::regex("\\s+$"), "");
					// Normalize whitespace
					m = std::regex_replace(m, std::regex("[\n\r\x0b\t ]+"), " ");
					// Replace HTML entities
					m = replace(m, "&lt;", "<");
					m = replace(m, "&gt;", ">");
					m = replace(m, "&quot;", "\"");
					m = replace(m, "&apos;", "'");
					m = replace(m, "&nbsp;", " ");
					m = replace(m, "&amp;", "&");

					return {TEXT, m};
				}
			}
		}

		if (in_tag)
		{
			in_tag = false;
			return {TAG_CLOSE, ""};
		}

		return {-1, ""}; // End of input
	};
}

// Parse tokens into a list of entities
std::vector<Entity> parseTokens(std::function<std::tuple<int, std::string>()> tokenize)
{
	std::vector<StackElement> stack;
	std::vector<Entity> entities;

	while (true)
	{
		auto [id, text] = tokenize();
		if (id == -1)
			break;

		if (id == TEXT)
		{
			// Push the text onto the stack
			stack.push_back({id, text, ""});
		}
		else if (id == TAG_VALUE)
		{
			// Set the value of the last tag on the stack
			if (!stack.empty())
			{
				stack.back().value = text;
			}
		}
		else if (id == TAG_CLOSE)
		{
			// Pop the stack until TAG_OPEN is found, creating the tag as an entity
			Entity tag;

			while (!stack.empty())
			{
				auto t = stack.back();
				stack.pop_back();

				if (t.id == TAG_OPEN)
				{
					if (t.text == "</")
						tag.close = true;
					break;
				}

				if (t.id == TAG_TYPE)
				{
					tag.type = t.text;
				}
				else if (t.text == "type" || t.text == "children" || t.text == "attributes")
				{
					tag.attributes[t.text] = t.value;
				}
				else
				{
					tag.top_attributes[t.text] = t.value;
				}
			}

			if (text != "/>" && !tag.close)
				tag.open = true;

			if (no_end_tag[tag.type])
			{
				tag.close = false;
				tag.open = false;
			}

			entities.push_back(tag);
		}
		else
		{
			// Push the token onto the stack
			stack.push_back({id, text, ""});
		}
	}

	return entities;
}

// Function to pop elements from the stack until a specific tag type is found
std::tuple<std::vector<Entity>, Entity> pop_until(std::vector<Entity> &stack, const std::string &tag_type = "")
{
	std::vector<Entity> result;
	Entity tag;

	while (!stack.empty())
	{
		auto t = stack.back();
		stack.pop_back();

		if (t.close)
		{
			// Recursively build the children for the closing tag
			auto [children, open_tag] = pop_until(stack, t.type);
			t = open_tag;
			t.children = children;
		}
		else if (t.open && t.type == tag_type)
		{
			// Stop when the matching open tag is found
			tag = t;
			break;
		}

		result.push_back(t);
	}

	// Reverse the order of the children
	std::reverse(result.begin(), result.end());

	return {result, tag};
}

Value entity_to_object(const Entity &entity)
{
	std::map<std::string, Value> obj;

	obj["type"] = entity.type;

	std::map<std::string, Value> attributes;
	for (const auto &[key, value] : entity.attributes)
	{
		attributes[key] = value;
	}
	obj["attributes"] = attributes;
	for (const auto &[key, value] : entity.top_attributes)
	{
		obj[key] = value;
	}

	std::vector<Value> children;
	for (const auto &child : entity.children)
	{
		children.push_back(entity_to_object(child));
	}
	obj["children"] = children;

	return obj;
}

void xml_decode(Context &context) noexcept
{
	auto xml = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	auto tokenizer = tokenize(xml);
	auto entities = parseTokens(tokenizer);
	auto [ast, _] = pop_until(entities);

	std::vector<Value> result;
	for (const auto &entity : ast)
	{
		result.push_back(entity_to_object(entity));
	}

	context.stack.push(result);
}
