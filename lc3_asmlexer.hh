#ifndef ASMLEXER_H
#define ASMLEXER_H

#if !defined(yyFlexLexerOnce)
#include <FlexLexer.h>
#endif

#include "lc3_asmparser.hh"


namespace yy
{

struct lexer : ::yyFlexLexer
{
    lexer(std::istream* is = nullptr, std::ostream* os = nullptr) : ::yyFlexLexer(is, os) {}
    virtual ~lexer() override {}

    virtual parser::symbol_type lex(lc3::asmcontext& ctx);
};
}

#ifndef YY_DECL
#define YY_DECL \
    yy::parser::symbol_type yy::lexer::lex(lc3::asmcontext& ctx)
#endif // YY_DECL

#endif // ASMLEXER_H
