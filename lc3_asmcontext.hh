#ifndef ASMCONTEXT_H
#define ASMCONTEXT_H

// C++
#include <string>
#include <unordered_map>
#include <istream>

// Bison
#include "lc3_asmparser.hh"


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

    bool parse_stream(std::istream& is, const std::string& sname = "<stream input>");
    bool parse_string(const std::string& str, const std::string& sname = "<string input>");
    bool parse_file(const std::string& fname);
};

}

#ifndef YY_DECL
#define YY_DECL \
    yy::parser::symbol_type yylex(lc3::asmcontext& ctx)
YY_DECL;
#endif // YY_DECL

#endif // ASMCONTEXT_H
