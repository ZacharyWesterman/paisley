
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

$(EXE): functions.hpp $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS) -lcrypto

# functions.hpp: $(FUNC)
# 	@echo '#pragma once' > $@
# 	@echo '$(FTXT)' |  awk '{print $$1 " " $$2 }' | sed 's/^ $$//g' >> $@
# 	@echo '\ntypedef void (*Function)(Context &);' >> $@
# 	@echo 'const Function FUNCTIONS[] = {' >> $@
# 	@grep ',$$' ../../compiler/functions/codes.lua | awk '{print "\t" $$1 ","}' | sed -E 's/\b(bool|delete|union|char)\b/_\1/g' >> $@
# 	@echo '};' >> $@
# 	@echo 'const int FUNCTION_COUNT = sizeof(FUNCTIONS) / sizeof(Function);\n' >> $@

main.o: main.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

functions/%.o: functions/%.cpp functions/%.hpp
	$(CXX) $(CXXFLAGS) -Wno-maybe-uninitialized -c $< -o $@

%.o: %.cpp %.hpp
	$(CXX) $(CXXFLAGS) -c $< -o $@
