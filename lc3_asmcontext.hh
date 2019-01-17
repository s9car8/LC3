#ifndef ASMCONTEXT_H
#define ASMCONTEXT_H

// C++
#include <stdint.h>
#include <string>
#include <unordered_map>
#include <istream>

// Bison
#include "lc3_asmparser.hh"


typedef uint16_t u16;

namespace yy {  }

namespace lc3
{

struct asmcontext
{
    yy::location loc{};
    std::string file{};
    bool trace_parsing = false;
    bool trace_scanning = false;

    std::unordered_map<std::string, unsigned> symbol_table;
    std::vector<u16> code;

    bool parse_stream(std::istream& is, const std::string& sname = "<stream input>");
    bool parse_string(const std::string& str, const std::string& sname = "<string input>");
    bool parse_file(const std::string& fname);

    void add_instr(u16 i) { code.push_back(i); }
};

}

#ifndef YY_DECL
#define YY_DECL \
    yy::parser::symbol_type yylex(lc3::asmcontext& ctx)
YY_DECL;
#endif // YY_DECL

#endif // ASMCONTEXT_H
