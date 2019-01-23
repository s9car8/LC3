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


#define SCOMPR(n, sp) ({ struct {u16 x: sp;} s; *(int*)&s = n; s.x; })

void asmcontext::resolve(const std::string& label, unsigned label_pos)
{
    for (auto [pos, width] : unresolved[label]) {
        switch (width) {
            case 6: code[pos] |= SCOMPR(label_pos - pos - 1, 6)&0x3F; break;
            case 9: code[pos] |= SCOMPR(label_pos - pos - 1, 9)&0x1FF; break;
            case 11: code[pos] |= SCOMPR(label_pos - pos - 1, 11)&0x7FF; break;
            default: break;
        }
        // code[pos] |= scompr(label_pos - pos - 1, width)&((0x1<<width)-1);
    }
}
