// C++
#include <sstream>
#include <fstream>

// Local
#include "lc3_asmcontext.hh"
#include "lc3_asmparser.hh"
#include "lc3_asmlexer.hh"

using namespace lc3;


bool asmcontext::parse_stream(std::istream& is, const std::string& sname)
{
    file = sname;
    loc.initialize(&file);

    yy::lexer lexer(&is);
    lexer.set_debug(trace_scanning);
    yy::parser parse(lexer, *this);
    parse.set_debug_level(trace_parsing);

    auto res = parse();
    return res;
}

bool asmcontext::parse_string(const std::string& str, const std::string& sname)
{
    std::stringstream ss(str);
    return parse_stream(ss, sname);
}

bool asmcontext::parse_file(const std::string& fname)
{
    std::ifstream f(fname);
    return parse_stream(f, fname);
}

void asmcontext::resolve(const std::string& label, unsigned label_pos)
{
    for (auto [pos, width] : unresolved[label]) {
        code[pos] |= (label_pos - pos)&((0x1<<width)-1);
    }
}
