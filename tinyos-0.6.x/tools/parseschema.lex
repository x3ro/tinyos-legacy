/*									tab:4
 * parseschema.lex
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:  Sam Madden

 Lex files to tokenize a mote-schema file.  See parseschema.yacc for more
 information about the format of a mote-schema.

 */

%{
#include <math.h> //for atof()
#include "schema.h"
  extern int lineno;
%}

digit [0-9]
num -?{digit}+
float -?{digit}+"."{digit}*
whitespace [ \t]

%%
field { return (FIELD); }
type { return (TYPE); }
name { return (NAME); }
min { return (MIN); }
max { return (MAX); }
bits { return (BITS); }
units { return (UNITS); }
sample_cost {return (COST); }
sample_time {return (TIME); }
input {return (INPUT); }
sends {return (DIRECTION); }
accessorEvent {return (ACCESSOR); }
responseEvent {return (RESPONSE); }
int {yylval.val = kINT; return (INT_TYPE); }
integer {yylval.val = kINT; return (INT_TYPE); }
byte {yylval.val = kBYTE; return (BYTE_TYPE); }
long {yylval.val = kLONG; return (LONG_TYPE); }
double {yylval.val = kDOUBLE; return (DOUBLE_TYPE); }
float {yylval.val = kFLOAT; return (FLOAT_TYPE); }
string {yylval.val = kSTRING; return (STRING_TYPE); }
: { return (COLON); }
\{ { return (LEFTBRAC);}
\} { return (RIGHTBRAC);}
\"[^\n\"]*\" { 
  yylval.string = (char *)strdup(yytext + 1); 
  yylval.string[yyleng-2] = '\0'; 
  return (STRING); 
}
#.*  ;
{num} { yylval.val = atoi(yytext); return (NUMBER); }
{float} { yylval.fval = atof(yytext); return (FLOAT); }
whitespace ;
[^\n\t ]* { 
  yylval.string = (char *)strdup(yytext); 
  return (STRING); 
}
\n {lineno++;}

%%
