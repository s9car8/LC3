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
}

%param { lc3::asmcontext& ctx }

%code
{
#include "lc3_asmcontext.hh"
}

%token END 0
%token <std::string> IDENTIFIER
%token <int> NUMBER
%token <int> REGISTER;
%token <u16> ADD AND BR JMP RET JSR JSRR LD LDI LDR LEA NOT RTI ST STI STR TRAP

%left ','

%type <u16> operation

%%
program
:   program line
|   %empty
;

line
:   label_opt operation                 { std::cout << "LINE: 0x" << std::hex << $operation << std::dec << std::endl; ctx.add_instr($operation); }
;

label_opt
:   IDENTIFIER
|   %empty
;

operation
:   ADD[opcode] REGISTER[dr] ',' REGISTER[sr1] ',' REGISTER[sr2]        { $$ = ($opcode<<12) | ($dr<<9) | ($sr1<<6) | ($sr2); }
|   ADD[opcode] REGISTER[dr] ',' REGISTER[sr1] ',' NUMBER[imm5]         { $$ = ($opcode<<12) | ($dr<<9) | ($sr1<<6) | (0x20 | ($imm5&0x1F)); }
|   AND[opcode] REGISTER[dr] ',' REGISTER[sr1] ',' REGISTER[sr2]        { $$ = ($opcode<<12) | ($dr<<9) | ($sr1<<6) | ($sr2); }
|   AND[opcode] REGISTER[dr] ',' REGISTER[sr1] ',' NUMBER[imm5]         { $$ = ($opcode<<12) | ($dr<<9) | ($sr1<<6) | (0x20 | ($imm5&0x1F)); }
|   BR
|   JMP[opcode] REGISTER[baseR]                                         { $$ = ($opcode<<12) | ($baseR<<6); }
|   RET[opcode]                                                         { $$ = ($opcode<<12) | (0x7<<6); }
|   JSR
|   JSRR[opcode] REGISTER[baseR]                                        { $$ = ($opcode<<12) | ($baseR<<6); }
|   LD
|   LDI
|   LDR
|   LEA
|   NOT[opcode] REGISTER[dr] ',' REGISTER[sr]                           { $$ = ($opcode<<12) | ($dr<<9) | ($sr<<6); }
|   RTI[opcode]                                                         { $$ = ($opcode<<12); }
|   ST
|   STI
|   STR
|   TRAP[opcode] NUMBER[trapvect8]                                      { $$ = ($opcode<<12) | ($trapvect8); }
;

%%


void yy::parser::error(const location_type& l, const std::string& m)
{
    std::cerr << (l.begin.filename ? l.begin.filename->c_str() : "(undefined)");
    std::cerr << ':' << l.begin.line << ':' << l.begin.column
              << ':' << l.end.column << ": " << m << '\n';
}

int main(int argc, const char* argv[])
{
    lc3::asmcontext ctx;
    ctx.trace_parsing = true;

    return ctx.parse_stream(std::cin);
}
