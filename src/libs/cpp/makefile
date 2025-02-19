
CXX = g++
CXXFLAGS = -Wall -Wextra --pedantic -Werror -std=c++17 -O3 -I./

DIRS := ./ ./functions/
SRCS := $(wildcard $(addsuffix *.cpp, $(DIRS)))
OBJS := $(patsubst %.cpp,%.o,$(SRCS))
FUNC := $(wildcard $(addsuffix *.hpp, functions/))
FTXT := $(patsubst %,#include "%"\n,$(wildcard $(addsuffix *.hpp, functions/)))

.PHONY: all clean

all: main

clean:
	rm -f $(OBJS) main

main: functions.hpp $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

functions.hpp: $(FUNC)
	echo ' $(FTXT)' > $@

main.o: main.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.cpp %.hpp
	$(CXX) $(CXXFLAGS) -c $< -o $@
