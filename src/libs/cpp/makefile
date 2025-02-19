
CXX = c++
CXXFLAGS = -Wall -Wextra --pedantic -Werror -std=c++17 -O3 -I./

EXE = standalone_binary

DIRS := ./ ./functions/
SRCS := $(wildcard $(addsuffix *.cpp, $(DIRS)))
OBJS := $(patsubst %.cpp,%.o,$(SRCS))
FUNC := $(wildcard $(addsuffix *.hpp, functions/))
FTXT := $(patsubst %,\n#include "%",$(wildcard $(addsuffix *.hpp, functions/)))

.PHONY: all clean

all: $(EXE)

clean:
	rm -f $(OBJS) $(EXE)

$(EXE): functions.hpp $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS)

functions.hpp: $(FUNC)
	@echo '#pragma once $(FTXT)' | awk '{print $$1 " " $$2}' > $@

main.o: main.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.cpp %.hpp
	$(CXX) $(CXXFLAGS) -c $< -o $@
