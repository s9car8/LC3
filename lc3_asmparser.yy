%skeleton "lalr1.cc"
%require "3.2"
%language "c++"
%defines
%define api.token.constructor
%define api.value.type variant
%define api.location.file none
%define parse.assert
%define parse.trace
%define parse.error verbose
%locations

%code requires
{
#include <stdint.h>
#include <string>
#include <iostream>
#include <iomanip>


typedef uint16_t u16;
namespace lc3 { struct asmcontext; };
namespace yy { struct lexer; }
}

%lex-param { yy::lexer& lexer }
%parse-param { yy::lexer& lexer }
%param { lc3::asmcontext& ctx }

%code
{
#include "lc3_asmcontext.hh"
#include "lc3_asmlexer.hh"


yy::parser::symbol_type yylex(yy::lexer& lexer, lc3::asmcontext& ctx)
{
    return lexer.lex(ctx);
}

// Compreses signed number with sp marking sign-bit.
#define SCOMPR(n, sp) ({ struct {u16 x: sp;} s; *(int*)&s = n; s.x; })
}

%token END 0
%token <std::string> IDENTIFIER
%token <int> NUMBER
%token <std::string> STRING
%token <int> REGISTER;
%token <u16> ADD AND BR JMP RET JSR JSRR LD LDI LDR LEA NOT RTI ST STI STR TRAP
%token ORIG_D FILL_D BLKW_D STRINGZ_D /* NOTE(sergey): Here we ommit END directive, because the lexer just returns END token for it. */
%left ','

%%
program
:   program line
|   %empty
;

line
:   label_opt operation
|   label_opt directive
;

label_opt
:   IDENTIFIER                                                          { ctx.add_label($1); }
|   %empty
;

operation
:   ADD[opcode] REGISTER[dr] ',' REGISTER[sr1] ',' REGISTER[sr2]        { ctx.push_instr(($opcode<<12) | ($dr<<9) | ($sr1<<6) | ($sr2)); }
|   ADD[opcode] REGISTER[dr] ',' REGISTER[sr1] ',' NUMBER[imm5]         { ctx.push_instr(($opcode<<12) | ($dr<<9) | ($sr1<<6) | (0x20 | ($imm5&0x1F))); }
|   AND[opcode] REGISTER[dr] ',' REGISTER[sr1] ',' REGISTER[sr2]        { ctx.push_instr(($opcode<<12) | ($dr<<9) | ($sr1<<6) | ($sr2)); }
|   AND[opcode] REGISTER[dr] ',' REGISTER[sr1] ',' NUMBER[imm5]         { ctx.push_instr(($opcode<<12) | ($dr<<9) | ($sr1<<6) | (0x20 | ($imm5&0x1F))); }
|   BR[flags] IDENTIFIER[label]                                         { /* NOTE(sergey): The opcode for this instruction is 0x0. */
                                                                          if (auto it = ctx.symbol_table.find($label); it != ctx.symbol_table.end())
                                                                              ctx.push_instr($flags | (SCOMPR(it->second - ctx.pos() - 1, 9)&0x1FF));
                                                                          else { ctx.add_unresolved($label, 9); ctx.push_instr($flags); } }
|   JMP[opcode] REGISTER[baseR]                                         { ctx.push_instr(($opcode<<12) | ($baseR<<6)); }
|   RET[opcode]                                                         { ctx.push_instr(($opcode<<12) | (0x7<<6)); }
|   JSR[opcode] IDENTIFIER[label]                                       { if (auto it = ctx.symbol_table.find($label); it != ctx.symbol_table.end())
                                                                              ctx.push_instr(($opcode<<12) | 0x800 | (SCOMPR(it->second - ctx.pos() - 1, 11)&0x7FF));
                                                                          else { ctx.add_unresolved($label, 11); ctx.push_instr(($opcode<<12) | 0x800); } }
|   JSRR[opcode] REGISTER[baseR]                                        { ctx.push_instr(($opcode<<12) | ($baseR<<6)); }
|   LD[opcode] REGISTER[dr] ',' IDENTIFIER[label]                       { if (auto it = ctx.symbol_table.find($label); it != ctx.symbol_table.end())
                                                                              ctx.push_instr(($opcode<<12) | ($dr<<9) | (SCOMPR(it->second - ctx.pos() - 1, 9)&0x1FF));
                                                                          else { ctx.add_unresolved($label, 9); ctx.push_instr(($opcode<<12) | ($dr<<9)); } }
|   LDI[opcode] REGISTER[dr] ',' IDENTIFIER[label]                      { if (auto it = ctx.symbol_table.find($label); it != ctx.symbol_table.end())
                                                                              ctx.push_instr(($opcode<<12) | ($dr<<9) | (SCOMPR(it->second - ctx.pos() - 1, 9)&0x1FF));
                                                                          else { ctx.add_unresolved($label, 9); ctx.push_instr(($opcode<<12) | ($dr<<9)); } }
|   LDR[opcode] REGISTER[dr] ',' REGISTER[baseR] ',' NUMBER[offset6]    { ctx.push_instr(($opcode<<12) | ($dr<<9) | ($baseR<<6) | (SCOMPR($offset6, 6)&0x3F)); }
|   LEA[opcode] REGISTER[dr] ',' IDENTIFIER[label]                      { if (auto it = ctx.symbol_table.find($label); it != ctx.symbol_table.end())
                                                                              ctx.push_instr(($opcode<<12) | ($dr<<9) | (SCOMPR(it->second - ctx.pos() - 1, 9)&0x1FF));
                                                                          else { ctx.add_unresolved($label, 9); ctx.push_instr(($opcode<<12) | ($dr<<9)); } }
|   NOT[opcode] REGISTER[dr] ',' REGISTER[sr]                           { ctx.push_instr(($opcode<<12) | ($dr<<9) | ($sr<<6)); }
|   RTI[opcode]                                                         { ctx.push_instr(($opcode<<12)); }
|   ST[opcode] REGISTER[sr] ',' IDENTIFIER[label]                       { if (auto it = ctx.symbol_table.find($label); it != ctx.symbol_table.end())
                                                                              ctx.push_instr(($opcode<<12) | ($sr<<9) | (SCOMPR(it->second - ctx.pos() - 1, 9)&0x1FF));
                                                                          else { ctx.add_unresolved($label, 9); ctx.push_instr(($opcode<<12) | ($sr<<9)); } }
|   STI[opcode] REGISTER[sr] ',' IDENTIFIER[label]                      { if (auto it = ctx.symbol_table.find($label); it != ctx.symbol_table.end())
                                                                              ctx.push_instr(($opcode<<12) | ($sr<<9) | (SCOMPR(it->second - ctx.pos() - 1, 9)&0x1FF));
                                                                          else { ctx.add_unresolved($label, 9); ctx.push_instr(($opcode<<12) | ($sr<<9)); } }
|   STR[opcode] REGISTER[sr] ',' REGISTER[baseR] ',' NUMBER[offset6]    { ctx.push_instr(($opcode<<12) | ($sr<<9) | ($baseR<<6) | (SCOMPR($offset6, 6)&0x3F)); }
|   TRAP[opcode] NUMBER[trapvect8]                                      { ctx.push_instr(($opcode<<12) | ($trapvect8)); }
;

directive
:   ORIG_D NUMBER[pos]                                                  { /* NOTE(sergey): The label declared before .ORIG will be interpreted in an unexpected way. */
                                                                          assert($pos >= ctx.pos()); auto n = $pos - ctx.pos(); for (int i = 0; i < n; ++i) ctx.push_word(0); }
|   FILL_D NUMBER[value]                                                { ctx.push_word($value); }
|   BLKW_D NUMBER[size]                                                 { for (int i = 0; i < $size; ++i) ctx.push_word(0); }
|   STRINGZ_D STRING[str]                                               { for (auto ch: $str) ctx.push_word((u16)ch); ctx.push_word(0x0000); }
;

%%


void yy::parser::error(const location_type& l, const std::string& m)
{
    std::cerr << (l.begin.filename ? l.begin.filename->c_str() : "(undefined)");
    std::cerr << ':' << l.begin.line << ':' << l.begin.column
              << ':' << l.end.column << ": " << m << '\n';
}

#include <fstream>

int main(int argc, const char* argv[])
{
    if (argc != 3) { std::cout << "Usage: lc3asm <input-file> <output-file>." << std::endl; return -1; }
    std::string fin_name = argv[1];
    std::ifstream fin(fin_name);
    std::ofstream fout(argv[2]);

    if (!fin.is_open()) { std::cout << "Couln't open file \'" << argv[1] << "\'." << std::endl; return -2; }
    if (!fout.is_open()) { std::cout << "Couln't open file \'" << argv[1] << "\'." << std::endl; return -2; }

    lc3::asmcontext ctx;
    ctx.trace_parsing = true;

    std::cout << fin_name << std::endl;
    auto res = ctx.parse_stream(fin, fin_name);
    // if (!res) { int i = 0; std::cout << "Result:\n" << std::hex; for (u16 instr : ctx.code) std::cout << (i+=2)-2 << ": " << "0x" << instr << std::endl; std::cout << std::dec; }
    if (!res) for (auto x : ctx.code) {fout.write((const char*)&x, 2);}
    return res;
}
