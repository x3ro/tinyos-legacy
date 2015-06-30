/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
package net.tinyos.script;

//import sym.*;
import java_cup.runtime.*;

/* semantic value of token returned by scanner */
class TokenValue {
  public int lineBegin;
  public int charBegin;
  public String text;
  public String filename;
  
  TokenValue() {
  }
  
  TokenValue(String text, int lineBegin, int charBegin, String filename) {
    this.text = text;
    this.lineBegin = lineBegin + 1;
    this.charBegin = charBegin;
    this.filename = filename;
    if (this.filename == null) {
      filename = "no file";
    }
  }

  public String toString() {
    return filename + ": line " + lineBegin;
  }

  public boolean toBoolean() {
    return Boolean.valueOf(text).booleanValue();
  }
  
  public int toInt() {
    return Integer.valueOf(text).intValue();
  }
}

%%

%implements java_cup.runtime.Scanner
%function next_token
%type java_cup.runtime.Symbol

%eofval{
  return new Symbol(sym.EOF, null);
%eofval}

%{
  public String sourceFilename;
%}

%line
%char
%state COMMENTS

ALPHA=[A-Za-z_]
DIGIT=[0-9]
ALPHA_NUMERIC={ALPHA}|{DIGIT}
IDENT={ALPHA}({ALPHA_NUMERIC})*
NUMBER=({DIGIT})+
WHITE_SPACE=([\ \n\r\t\f])+
IF="IF"|"if"
THEN="THEN"|"then"
ELSE="ELSE"|"else"
END="END"|"end"
EQUAL="="
SUBTRACT="--"
MINUS="-"
PLUS="+"
PLUS_EQUAL="+="
DIVIDE="/"
STAR="*"
EXPONENT="^"
LESS_THAN="<"
GREATER_THAN=">"
LESS_EQUAL="<="
DOLLAR="$"
GREATER_EQUAL=">="
NOT_EQUAL="<>"
LOGICAL_AND="&"
LOGICAL_OR="|"
LOGICAL_NOT="~"
LOGICAL_XOR="#"
NOT="NOT"|"not"
AND="AND"|"and"
OR="OR"|"or"
XOR="XOR"|"xor"
EQV="EQV"|"eqv"
IMP="IMP"|"imp"
FOR="FOR"|"for"
TO="TO"|"to"
NEXT="NEXT"|"next"
STEP="STEP"|"step"
UNTIL="UNTIL"|"until"
WHILE="WHILE"|"while"
END="END"|"end"
PRIVATE="PRIVATE"|"private"
SHARED="SHARED"|"shared"
BUFFER="BUFFER"|"buffer"
CALL="CALL"|"call"
RPAREN=")"
LPAREN="("
RBRACKET="]"
LBRACKET="["
COMMA=","
SEMICOLON=";"
COLON=":"
NAME={IDENT}
CONSTANT={NUMBER}


%%


<YYINITIAL> {IMP} {
  return new Symbol(sym.IMP, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {CALL} {
  return new Symbol(sym.CALL, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {EQV} {
  return new Symbol(sym.EQV, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {XOR} {
  return new Symbol(sym.XOR, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {AND} {
  return new Symbol(sym.AND, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {OR} {
  return new Symbol(sym.OR, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {LESS_EQUAL} {
  return new Symbol(sym.LESS_EQUAL, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {RPAREN} {
  return new Symbol(sym.RPAREN, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {DOLLAR} {
  return new Symbol(sym.DOLLAR, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {PRIVATE} {
  return new Symbol(sym.PRIVATE, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {SHARED} {
  return new Symbol(sym.SHARED, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {BUFFER} {
  return new Symbol(sym.BUFFER, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {PLUS_EQUAL} {
  return new Symbol(sym.PLUS_EQUAL, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {LPAREN} {
  return new Symbol(sym.LPAREN, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {LBRACKET} {
  return new Symbol(sym.LBRACKET, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {RBRACKET} {
  return new Symbol(sym.RBRACKET, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {EQUAL} {
  return new Symbol(sym.EQUAL, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {GREATER_THAN} {
  return new Symbol(sym.GREATER_THAN, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {NOT} {
  return new Symbol(sym.NOT, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {COMMA} {
  return new Symbol(sym.COMMA, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {COLON} {
  return new Symbol(sym.COLON, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {NOT_EQUAL} {
  return new Symbol(sym.NOT_EQUAL, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {GREATER_EQUAL} {
  return new Symbol(sym.GREATER_EQUAL, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {LPAREN} {
  return new Symbol(sym.LPAREN, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {LESS_THAN} {
  return new Symbol(sym.LESS_THAN, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}


<YYINITIAL> {IF} {
  return new Symbol(sym.IF, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {THEN} {
  return new Symbol(sym.THEN, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {ELSE} {
  return new Symbol(sym.ELSE, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {END} {
  return new Symbol(sym.END, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {FOR} {
  return new Symbol(sym.FOR, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {TO} {
  return new Symbol(sym.TO, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {NEXT} {
  return new Symbol(sym.NEXT, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {STEP} {
  return new Symbol(sym.STEP, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {UNTIL} {
  return new Symbol(sym.UNTIL, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {WHILE} {
  return new Symbol(sym.WHILE, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {SUBTRACT} {
  return new Symbol(sym.SUBTRACT, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {MINUS} {
  return new Symbol(sym.MINUS, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {PLUS} {
  return new Symbol(sym.PLUS, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {DIVIDE} {
  return new Symbol(sym.DIVIDE, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {STAR} {
  return new Symbol(sym.STAR, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {EXPONENT} {
  return new Symbol(sym.EXPONENT, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {XOR} {
  return new Symbol(sym.XOR,  new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {COLON} {
  return new Symbol(sym.COLON,  new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {SEMICOLON} {
  return new Symbol(sym.SEMICOLON,  new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {LOGICAL_NOT} {
  return new Symbol(sym.LOGICAL_NOT,  new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {LOGICAL_OR} {
  return new Symbol(sym.LOGICAL_OR,  new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {LOGICAL_XOR} {
  return new Symbol(sym.LOGICAL_XOR,  new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {LOGICAL_AND} {
  return new Symbol(sym.LOGICAL_AND,  new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

<YYINITIAL> {NAME} {
  return new Symbol(sym.NAME, new String(yytext()));
}

<YYINITIAL> {CONSTANT} {
  return new Symbol(sym.CONSTANT, new Integer(Integer.parseInt(yytext())));
}

<YYINITIAL> {WHITE_SPACE} { }

<YYINITIAL> "!" {
  yybegin(COMMENTS);
}
<COMMENTS> [^\n] {
}
<COMMENTS> [\n] {
  yybegin(YYINITIAL);
}

<YYINITIAL> . {
  return new Symbol(sym.error, new TokenValue(yytext(), yyline, yychar, sourceFilename));
}

