#pragma once
#include "value.hpp"

class Stack : public std::vector<Value>
{
public:
	Stack(std::initializer_list<Value> values) noexcept : std::vector<Value>(values) {}

	Value pop() noexcept;
	void push(const Value &value) noexcept;

	void print() const noexcept;
};
