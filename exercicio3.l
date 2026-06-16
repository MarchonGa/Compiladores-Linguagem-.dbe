%option noyywrap
%x COMMENT

%{
#include <string.h>
#include <stdlib.h>
#include "exercicio3.tab.h"
%}

NUM        ([0-9]+([.][0-9]+)?|[.][0-9]+)
VAR_NAME   [a-zA-Z_]([a-zA-Z0-9]|_)*
TXT        \"([^\\\"\n]|\\.)*\"

%%

"//"[^\n]*              { /* Comentario de uma linha */ }
"d/"                    { BEGIN(COMMENT); }
<COMMENT>"\\b"          { BEGIN(INITIAL); }
<COMMENT>\n             { /* Ignora quebra dentro do comentario */ }
<COMMENT>.              { /* Ignora conteudo do comentario */ }

"INICIO"                { return INICIO; }
"FIM"                   { return FIM; }

"inteiro"               { return TIPO_INTEIRO; }
"real"                  { return TIPO_REAL; }
"texto"                 { return TIPO_TEXTO; }

"escrever"              { return OUT; } /* printf(""); */
"ler"                   { return IN; }  /* scanf("");  */

"SE"                    { return IF; }
"SENAO"                 { return ELSE; }

"WHEN"                  { return WHEN; }
"DO"                    { return DO; }

"&&"                    { return AND; }
"||"                    { return OR; }
"!"                     { return NOT; }

">="                    { yylval.op_log = 3; return CMP; }
"<="                    { yylval.op_log = 4; return CMP; }
"=="                    { yylval.op_log = 5; return CMP; }
"!="                    { yylval.op_log = 6; return CMP; }
">"                     { yylval.op_log = 1; return CMP; }
"<"                     { yylval.op_log = 2; return CMP; }

"BK"                    { return BK; } /* Break line || \n */

{NUM} {
    yylval.real = atof(yytext);
    return NUM;
}

{TXT} {
    strcpy(yylval.str, yytext);
    return TXT;
}

{VAR_NAME} {
    strcpy(yylval.str, yytext);
    return VAR_NAME;
}

"+"                     { return '+'; }
"-"                     { return '-'; }
"*"                     { return '*'; }
"/"                     { return '/'; }
"^"                     { return '^'; }
"="                     { return '='; }
"("                     { return '('; }
")"                     { return ')'; }
"{"                     { return '{'; }
"}"                     { return '}'; }
"["                     { return '['; }
"]"                     { return ']'; }
","                     { return ','; }
";"                     { return ';'; }

[ \t\r\n]+              { /*Ignora espacos */ }

. {
    printf("Caractere invalido: %s\n", yytext);
}

%%
