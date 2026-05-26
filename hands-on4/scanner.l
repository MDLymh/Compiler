%option noyywrap

%{
#include "parser.tab.h"
#include <string.h>
#include <stdlib.h>

int line_num = 1;
%}

digit       [0-9]
id          [a-zA-Z_][a-zA-Z0-9_]*
string      \"[^\"]*\"

%%

"#include"  { return INCLUDE; }
"#define"   { return DEFINE; }

"int"       { return INT; }
"func"      { return FUNC; }
"if"        { return IF; }
"return"    { return RETURN; }

"//"[^\n\r]*  ;

{string}    {
                yylval.str = strdup(yytext);
                return STRING_LITERAL;
            }

{digit}+    {
                yylval.str = strdup(yytext);
                return NUMBER;
            }

{id}        {
                yylval.str = strdup(yytext);
                return ID;
            }

"("         { return PARIZQ; }
")"         { return PARDER; }
"{"         { return LLAVEIZQ; }
"}"         { return LLAVEDER; }
";"         { return PUNTOYCOMA; }
","         { return COMA; }
"="         { return IGUAL; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return TIMES; }
"/"         { return DIVIDE; }
"<"         { return MENOR; }
">"         { return MAYOR; }
"."         { return PUNTO; }

[ \t\r]+   ;

\n          { line_num++; }

.           { return yytext[0]; }

%%

