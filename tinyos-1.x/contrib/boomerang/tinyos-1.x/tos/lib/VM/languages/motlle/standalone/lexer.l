/*
 * Copyright (c) 1993-1999 David Gay and Gustav Hållberg
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software for any
 * purpose, without fee, and without written agreement is hereby granted,
 * provided that the above copyright notice and the following two paragraphs
 * appear in all copies of this software.
 * 
 * IN NO EVENT SHALL DAVID GAY OR GUSTAV HALLBERG BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF DAVID GAY OR
 * GUSTAV HALLBERG HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * DAVID GAY AND GUSTAV HALLBERG SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN
 * "AS IS" BASIS, AND DAVID GAY AND GUSTAV HALLBERG HAVE NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

%{
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include "mudlle.h"
#include "mparser.h"
#include "lexer.h"
#include "env.h"
#include "compile.h"
#include "utils.h"
#include "types.h"

#define YY_DECL static int yylex_internal(void)

/* We never wrap into another file */
#define YY_SKIP_YYWRAP
#define yywrap() (1)

#define YY_USE_PROTOS

#undef YY_INPUT
#define YY_INPUT(buf, result, max_size) \
  { if (!line_read) (result) = read(fileno(yyin), (buf), (max_size)); \
  else (result) = string_read((buf), (max_size)); }

static int string_read(char *buf, int max_size);

static YY_BUFFER_STATE mbuf;
static int line_read;
static const char *line;
static int length;
struct location lexloc;
static bool schemefile;

struct lkeyword {
  const char *name;
  int value;
};

static struct lkeyword keywords[] = {
  { "fn", FUNCTION },
  { "if", IF },
  { "else", ELSE },
  { "while", WHILE },
  { "for", FOR },
  { "do", DO },
  { "break", BREAK },
  { "continue", CONTINUE },
  { "return", RETURN },
  { "switch", SWITCH },
  { "case", CASE },
  { "default", DEFAULT },

  { "library", LIBRARY },
  { "module", MODULE },
  { "requires", IMPORTS },
  { "reads", READS },
  { "writes", WRITES },
  { "defines", DEFINES },
  { "scheme", SCHEME },
  { "schemefile", SCHEMEFILE }
};
#define NKEYWORDS (sizeof keywords / sizeof(struct lkeyword))

%}

DIGIT           [0-9]
NONZERODIGIT	[1-9]
OCTDIGIT	[0-7]
EXP		[eE][+-]?{DIGIT}+
DECIM		\.{DIGIT}+
HEXDIGIT	[0-9a-fA-F]
SYMBOL_NAME     [_a-zA-Z][a-zA-Z0-9$_?!]*
SCHEME_SYMBOL   [!$%&*/:<=>?~_^a-zA-Z][!$%&*/:<=>?~_^a-zA-Z0-9.+-]*

%x schemelex

%%

<INITIAL,schemelex>\n { lexloc.lineno++; }
<INITIAL,schemelex>[ \t\r]+  { }

<schemelex>;.*\n { lexloc.lineno++; }
\/\/.*\n  { lexloc.lineno++; }
^\#!.*\n  { lexloc.lineno++; }
\/\*     { /* start of multi-line comment */
	   /* find end of comment */
	   int depth = 1, c, star = FALSE, slash = FALSE;

#ifndef __cplusplus
#define yyinput input
#endif
	   while (depth > 0 && (c = yyinput()) != EOF)
	     {
	       if (c == '\n') lexloc.lineno++;
	       else if (c == '*' && slash) depth++;
	       else if (c == '/' && star) depth--;
	       star = c == '*';
	       slash = c == '/';
	     }
         }
<INITIAL,schemelex>"("	{ yylval.location = lexloc; return '('; }
<INITIAL,schemelex>")"	{ return ')'; }
<INITIAL,schemelex>"'"	{ yylval.location = lexloc; return QUOTE; }
<INITIAL,schemelex>"."	{ return '.'; }
<INITIAL,schemelex>","  { return ','; }

"["	{ yylval.location = lexloc; return '['; }
"]"	{ return ']'; }
"{"	{ yylval.location = lexloc; return '{'; }
"}"	{ return '}'; }
"="	{ return ASSIGN; }
"&&"	{ return SC_AND; }
"||"	{ return SC_OR; }
"^^"    { return XOR; }
"!"	{ return NOT; }
"|"	{ return '|'; }
":"	{ return ':'; }
";"	{ return ';'; }
"+"	{ return '+'; }
"-"	{ return '-'; }
"*"	{ return '*'; }
"/"	{ return '/'; }
"%"	{ return '%'; }
"&"	{ return '&'; }
"~"	{ return '~'; }
"^"	{ return '^'; }
"+="	{ yylval.operator = b_add; return OP_ASSIGN; }
"-="	{ yylval.operator = b_subtract; return OP_ASSIGN; }
"*="	{ yylval.operator = b_multiply; return OP_ASSIGN; }
"/="	{ yylval.operator = b_divide; return OP_ASSIGN; }
"%="	{ yylval.operator = b_remainder; return OP_ASSIGN; }
"^="	{ yylval.operator = b_bitxor; return OP_ASSIGN; }
"&="	{ yylval.operator = b_bitand; return OP_ASSIGN; }
"|="	{ yylval.operator = b_bitor; return OP_ASSIGN; }
"&&="	{ yylval.operator = b_sc_and; return OP_ASSIGN; }
"^^="	{ yylval.operator = b_xor; return OP_ASSIGN; }
"||="	{ yylval.operator = b_sc_or; return OP_ASSIGN; }
">>="	{ yylval.operator = b_shift_right; return OP_ASSIGN; }
"<<="	{ yylval.operator = b_shift_left; return OP_ASSIGN; }
"=="	{ return EQ; }
"!="	{ return NE; }
"<"	{ return LT; }
"<="	{ return LE; }
">"	{ return GT; }
">="	{ return GE; }
"<<"	{ return SHIFT_LEFT; }
">>"	{ return SHIFT_RIGHT; }
"++"    { yylval.operator = b_add; return INCREMENTER; }
"--"    { yylval.operator = b_subtract; return INCREMENTER; }
"@"	{ return '@'; }
"_"     { return SINK; }
"..."   { return ELLIPSIS; }

'\\.'	{
	  switch (yytext[2])
	    {
	    case 'n': yylval.integer = '\n'; break;
	    case 'r': yylval.integer = '\r'; break;
	    case 't': yylval.integer = '\t'; break;
	    case 'f': yylval.integer = '\f'; break;
	    default: yylval.integer = (unsigned char) yytext[2]; break;
	    }
	  return INTEGER;
	}
'[^\\]'	{ yylval.integer = (unsigned char) yytext[1]; return INTEGER; }

<INITIAL,schemelex>(#[bodx])?-?({DIGIT}+|0[xX]{HEXDIGIT}+) {
	  if (!mudlle_strtoint(yytext, &yylval.integer))
	    log_error(lexloc, "Integer constant out of bounds.");
	  else
            return INTEGER; 
	}

<INITIAL,schemelex>-?{DIGIT}+(({DECIM}{EXP}?)|{EXP}) {
          if (!mudlle_strtofloat(yytext, &yylval.mudlle_float))
	    log_error(lexloc, "illegal floating point number");
	  else
            return FLOAT;
	}

<INITIAL,schemelex>\"([^\n\\"]*(\\(.|\n))?)+\" {char *str = yylval.string =
				allocate(parser_memory, strlen(yytext));
			      const char *text = yytext + 1;

			      while (*text)
				if (*text == '\\' && text[1])
				  {
				    switch (text[1])
				      {
				      case '\n': lexloc.lineno++; break;
				      case 'n': *str++ = '\n'; break;
				      case 'r': *str++ = '\r'; break;
				      case 't': *str++ = '\t'; break;
				      default: *str++ = text[1]; break;
				      }
				    text += 2;
				  }
				else *str++ = *text++;

			      str[-1] = '\0';
			      return STRING;
			    }
{SYMBOL_NAME} { 
	        int i;

		yylval.symbol = allocate(parser_memory,strlen(yytext) + 1);
		strlwr(strcpy(yylval.symbol, yytext));

		for (i = 0; i < NKEYWORDS; i++)
		  if (stricmp(yytext, keywords[i].name) == 0)
		    {
		      yylval.location = lexloc;
		      return keywords[i].value;
		    }

		return SYMBOL;
	      }

<schemelex>({SCHEME_SYMBOL}|[+]|[-]|[|]) {
		yylval.symbol = allocate(parser_memory,strlen(yytext) + 1);
		strlwr(strcpy(yylval.symbol, yytext));

		return SYMBOL;
	      }
<schemelex>#\( { yylval.location = lexloc; return '['; }

<schemelex>#\\space { yylval.integer = ' '; return INTEGER; }
<schemelex>#\\newline { yylval.integer = '\n'; return INTEGER; }
<schemelex>#\\. { yylval.integer = yytext[2]; return INTEGER; }
<schemelex>#t { yylval.integer = 1; return INTEGER; }
<schemelex>#f { yylval.integer = 0; return INTEGER; }

<INITIAL,schemelex>.	{ log_error(lexloc, "Bad character %s(%02x)", yytext, (unsigned char)yytext[0]); }

%%

static int string_read(char *abuf, int max_size)
{
  int cnt;

  cnt = max_size;
  if (cnt > length) cnt = length;

  memcpy(abuf, line, cnt);
  line += cnt;
  length -= cnt;

  return cnt;
}


void read_from_file(FILE *f, bool is_scheme)
{
  if (!mbuf) mbuf = yy_create_buffer(f, YY_BUF_SIZE);
  else yy_init_buffer(mbuf, f);
  
  yy_current_buffer = 0;
  yy_switch_to_buffer(mbuf);
  line_read = FALSE;
  lexloc.lineno = 1;
  normal_lexing();
  schemefile = is_scheme;
}

void read_from_string(const char *str, bool is_scheme)
{
  if (!mbuf) mbuf = yy_create_buffer(stdin, YY_BUF_SIZE);
  else yy_init_buffer(mbuf, stdin);
  
  yy_current_buffer = 0;
  yy_switch_to_buffer(mbuf);
  line_read = TRUE;
  line = str;
  length = strlen(line);
  lexloc.lineno = 0;
  normal_lexing();
  schemefile = is_scheme;
}

void scheme_lexing(void)
{
  BEGIN(schemelex);
}

void normal_lexing(void)
{
  BEGIN(INITIAL);
}

int yylex(void)
{
  /* Force a SCHEMEFILE token to dispatch to the correct grammar rule,
     when requested */
  if (schemefile)
    {
      schemefile = FALSE;
      return SCHEMEFILE;
    }
  return yylex_internal();
}
