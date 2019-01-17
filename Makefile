# MAKEFLAGS := -s

CXX := g++
YACC := bison
LEX := flex

CXXFLAGS := -Wall -std=gnu++2a

TEMP_FILES :=

all:  lc3 lc3asm
	cat test2.asm | ./lc3asm && ./lc3

TEMP_FILES += lc3
lc3: lc3.cpp
	$(CXX) $^ $(CXXFLAGS) -o $@

lc3asm-p := lc3_asmparser
lc3asm-parser := $(addprefix $(lc3asm-p),.hh .cc)
TEMP_FILES += $(lc3asm-parser) $(lc3asm-p).output
$(lc3asm-parser): $(lc3asm-p).yy
	$(YACC) $< --report=all -o $(lastword $(lc3asm-parser)) \
		--defines=$(firstword $(lc3asm-parser))

lc3asm-l := lc3_asmlexer
lc3asm-lexer := $(addprefix $(lc3asm-l),.cc)
TEMP_FILES += $(lc3asm-lexer)
$(lc3asm-lexer): $(lc3asm-l).ll
	$(LEX) -o $(lastword $(lc3asm-lexer)) $<

TEMP_FILES += lc3asm
lc3asm: $(lc3asm-parser) $(lc3asm-lexer) lc3_asmcontext.cc
	$(CXX) $^ $(CXXFLAGS) -o $@

.PHONY: clean
clean:
	-rm -r .*.o $(TEMP_FILES) 2> /dev/null
