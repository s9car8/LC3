%{
#include <stdlib.h>
#include <string>
#include "lc3_asmcontext.hh"
#include "lc3_asmparser.hh"

typedef yy::parser::token token;
typedef yy::parser::token_type token_type;
typedef yy::parser::symbol_type symbol_type;
typedef yy::parser::location_type location_type;

#define yyterminate() return yy::parser::make_END(loc);

auto make_NUMBER(const std::string& s, const location_type& loc)
    -> decltype(yy::parser::make_NUMBER(int(), loc));
%}

%option noyywrap nounput batch debug

%{
/* Run each time a pattern is matched. */
#define YY_USER_ACTION loc.columns(yyleng);
%}

digit   [0-9]
number  {digit}+
id      [A-Za-z][A-Za-z0-9_]*
%%
%{
    auto& loc = ctx.loc;
    loc.step(); /* reset location */
%}

#{number}               { return make_NUMBER(yytext, loc); }
{id}                    { return yy::parser::make_IDENTIFIER(yytext, loc); }
[ \t]+                  { loc.step(); }
\n+                     { loc.lines(yyleng); loc.step(); }
;.*$                    { /* Comment */ }
.                       { return {static_cast<token_type>(*yytext), *yytext, std::move(loc)}; }

%%

auto make_NUMBER(const std::string& s, const location_type& loc)
    -> decltype(yy::parser::make_NUMBER(int(), loc))
{
    errno = 0;
    long res = strtol(s.c_str(), NULL, 10);
    if (errno) throw yy::parser::syntax_error(loc, "Invalid integer: " + s);
    return yy::parser::make_NUMBER((int) res, loc);
}
