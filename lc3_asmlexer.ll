%{
#include <stdlib.h>
#include <stdio.h>
#include <string>
#include "lc3_asmcontext.hh"
#include "lc3_asmparser.hh"

typedef yy::parser::token token;
typedef yy::parser::token_type token_type;
typedef yy::parser::symbol_type symbol_type;
typedef yy::parser::location_type location_type;

#define yyterminate() return yy::parser::make_END(loc);

auto make_REGISTER(const std::string& s, const location_type& loc)
    -> yy::parser::symbol_type;
auto make_NUMBER(const std::string& s, int base, const location_type& loc)
    -> yy::parser::symbol_type;
%}

%option noyywrap nounput

%{
/* Run each time a pattern is matched. */
#define YY_USER_ACTION loc.columns(yyleng);
%}

dec     [0-9]+
bin     [0-1]+
hex     [0-9a-fA-F]+
id      [A-Za-z][A-Za-z0-9_]{1,20}
%%
%{
    auto& loc = ctx.loc;
    loc.step(); /* reset location */
%}

R{dec}                  { return make_REGISTER(yytext + 1, loc); }
#{dec}                  { return make_NUMBER(yytext + 1, 10, loc); }
b{bin}                  { return make_NUMBER(yytext + 1, 2, loc); }
x{hex}                  { return make_NUMBER(yytext + 1, 16, loc); }
"add"|"ADD"             { return yy::parser::make_ADD(0x1, loc); }
"and"|"AND"             { return yy::parser::make_AND(0x5, loc); }
"br"|"BR"               { return yy::parser::make_BR(0x0, loc); }
"jmp"|"JMP"             { return yy::parser::make_JMP(0xC, loc); }
"ret"|"RET"             { return yy::parser::make_RET(0xC, loc); }
"jsr"|"JSR"             { return yy::parser::make_JSR(0x4, loc); }
"jsrr"|"JSRR"           { return yy::parser::make_JSRR(0x4, loc); }
"ld"|"LD"               { return yy::parser::make_LD(0x2, loc); }
"ldi"|"LDI"             { return yy::parser::make_LDI(0xA, loc); }
"ldr"|"LDR"             { return yy::parser::make_LDR(0x6, loc); }
"lea"|"LEA"             { return yy::parser::make_LEA(0xE, loc); }
"not"|"NOT"             { return yy::parser::make_NOT(0x9, loc); }
"rti"|"RTI"             { return yy::parser::make_RTI(0x8, loc); }
"st"|"ST"               { return yy::parser::make_ST(0x3, loc); }
"sti"|"STI"             { return yy::parser::make_STI(0xB, loc); }
"str"|"STR"             { return yy::parser::make_STR(0x7, loc); }
"trap"|"TRAP"           { return yy::parser::make_TRAP(0xF, loc); }
{id}                    { printf("<ID, \'%s\'>\n", yytext); return yy::parser::make_IDENTIFIER(yytext, loc); }
[ \t]+                  { loc.step(); }
\n+                     { loc.lines(yyleng); loc.step(); }
;.*$                    { /* Comment */ }
.                       { return {token_type(*yytext&0xFF), std::move(loc)}; }

%%

auto make_REGISTER(const std::string& s, const location_type& loc)
    -> yy::parser::symbol_type
{
    errno = 0;
    long res = strtol(s.c_str(), NULL, 10);
    if (errno) throw yy::parser::syntax_error(loc, "Invalid integer: " + s);
    else if (res < 0 || res > 7) throw yy::parser::syntax_error(loc, "Invalid register number: " + s + ". Only R0-R7 allowed.");
    return yy::parser::make_REGISTER((int) res, loc);
}

auto make_NUMBER(const std::string& s, int base, const location_type& loc)
    -> yy::parser::symbol_type
{
    errno = 0;
    long res = strtol(s.c_str(), NULL, base);
    if (errno) throw yy::parser::syntax_error(loc, "Invalid integer: " + s);
    return yy::parser::make_NUMBER((int) res, loc);
}
