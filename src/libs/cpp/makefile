
CXX = c++
CXXFLAGS = -Wall -Wextra --pedantic -Werror -std=c++17 -Ofast -I./

EXE = standalone_binary

DIRS := ./ ./functions/ ./actions/
SRCS := $(wildcard $(addsuffix *.cpp, $(DIRS)))
OBJS := $(patsubst %.cpp,%.o,$(SRCS))
FUNC := $(wildcard $(addsuffix *.hpp, functions/))
FTXT := $(patsubst %,\n#include "%",$(wildcard $(addsuffix *.hpp, functions/)))
FNAM := $(patsubst functions/%.hpp,%,$(wildcard $(addsuffix *.hpp, functions/)))

.PHONY: all clean

all: $(EXE)

clean:
	rm -f $(OBJS) $(EXE)

$(EXE): PAISLEY_BYTECODE.o $(OBJS)
	@echo Linking...
	@$(CXX) $(CXXFLAGS) -o $@ $^ -lcrypto

PAISLEY_BYTECODE.o : PAISLEY_BYTECODE.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

main.o: main.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

functions/%.o: functions/%.cpp functions/%.hpp
	$(CXX) $(CXXFLAGS) -Wno-maybe-uninitialized -c $< -o $@

actions/pop_catch_or_throw.o: actions/pop_catch_or_throw.cpp actions/pop_catch_or_throw.hpp
	$(CXX) $(CXXFLAGS) -Wno-maybe-uninitialized -c $< -o $@

%.o: %.cpp %.hpp
	$(CXX) $(CXXFLAGS) -c $< -o $@
