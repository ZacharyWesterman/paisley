#pragma once

#include "context.hpp"

typedef void (*Function)(Context &);
extern const Function FUNCTIONS[];
extern const int FUNCTION_COUNT;
