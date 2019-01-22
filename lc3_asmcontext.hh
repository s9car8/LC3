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
    std::unordered_map<std::string, std::vector<std::pair<unsigned, unsigned>>> unresolved;
    std::vector<u16> code;

    bool parse_stream(std::istream& is, const std::string& sname = "<stream input>");
    bool parse_string(const std::string& str, const std::string& sname = "<string input>");
    bool parse_file(const std::string& fname);

    int pos() const { return code.size(); }
    void push_instr(u16 i) { code.push_back(i); }
    void push_word(u16 i) { code.push_back(i); }
    void add_label(const std::string& label) { symbol_table.emplace(label, pos()); resolve(label, pos()); }
    void add_unresolved(const std::string& label, unsigned width) { unresolved[label].emplace_back(pos(), width); }

    void resolve(const std::string& label, unsigned label_pos);
};

}

#endif // ASMCONTEXT_H
