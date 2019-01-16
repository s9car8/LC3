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

namespace lc3 { struct asmcontext; };

typedef uint16_t u16;
}

%param { lc3::asmcontext& ctx }

%code
{
#include "lc3_asmcontext.hh"
}

%token END 0
%token <std::string> IDENTIFIER
%token <int>         NUMBER
%token <int>         REGISTER;
%token INDENT " "

%left ','

%type <u16> opcode operands operand

%%
program
:   program line
|   %empty
;

line
:   label_opt INDENT opcode operands
;

label_opt
:   IDENTIFIER
|   %empty
;

opcode
:   IDENTIFIER  { $$ = 0; }
;

operands
:   operands ',' operands
|   operand
|   %empty
;

operand
:   IDENTIFIER
|   NUMBER
|   REGISTER
;

%%

#include <iostream>


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
