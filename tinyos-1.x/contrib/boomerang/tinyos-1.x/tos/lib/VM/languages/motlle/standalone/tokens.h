/* A Bison parser, made by GNU Bison 1.875.  */

/* Skeleton parser for GLR parsing with Bison,
   Copyright (C) 2002 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     FUNCTION = 258,
     IF = 259,
     ELSE = 260,
     WHILE = 261,
     FOR = 262,
     ASSIGN = 263,
     BREAK = 264,
     CONTINUE = 265,
     RETURN = 266,
     SINK = 267,
     SWITCH = 268,
     CASE = 269,
     DEFAULT = 270,
     ELLIPSIS = 271,
     DO = 272,
     MODULE = 273,
     LIBRARY = 274,
     IMPORTS = 275,
     DEFINES = 276,
     READS = 277,
     WRITES = 278,
     SYMBOL = 279,
     INTEGER = 280,
     STRING = 281,
     FLOAT = 282,
     OP_ASSIGN = 283,
     INCREMENTER = 284,
     SCHEME = 285,
     SCHEMEFILE = 286,
     QUOTE = 287,
     XOR = 288,
     OR = 289,
     SC_OR = 290,
     AND = 291,
     SC_AND = 292,
     GE = 293,
     GT = 294,
     LE = 295,
     LT = 296,
     NE = 297,
     EQ = 298,
     SHIFT_RIGHT = 299,
     SHIFT_LEFT = 300,
     UMINUS = 301,
     NOT = 302
   };
#endif
#define FUNCTION 258
#define IF 259
#define ELSE 260
#define WHILE 261
#define FOR 262
#define ASSIGN 263
#define BREAK 264
#define CONTINUE 265
#define RETURN 266
#define SINK 267
#define SWITCH 268
#define CASE 269
#define DEFAULT 270
#define ELLIPSIS 271
#define DO 272
#define MODULE 273
#define LIBRARY 274
#define IMPORTS 275
#define DEFINES 276
#define READS 277
#define WRITES 278
#define SYMBOL 279
#define INTEGER 280
#define STRING 281
#define FLOAT 282
#define OP_ASSIGN 283
#define INCREMENTER 284
#define SCHEME 285
#define SCHEMEFILE 286
#define QUOTE 287
#define XOR 288
#define OR 289
#define SC_OR 290
#define AND 291
#define SC_AND 292
#define GE 293
#define GT 294
#define LE 295
#define LT 296
#define NE 297
#define EQ 298
#define SHIFT_RIGHT 299
#define SHIFT_LEFT 300
#define UMINUS 301
#define NOT 302




#if ! defined (YYSTYPE) && ! defined (YYSTYPE_IS_DECLARED)
#line 37 "../standalone/parser.y"
typedef union YYSTYPE {
  location location;
  char *string;
  char *symbol;
  int integer;
  int operator;
  float mudlle_float;
  constant tconstant;
  block tblock;
  function tfunction;
  clist tclist;
  vlist tvlist;
  cstlist tcstlist;
  cstpair tcstpair;
  component tcomponent;
  mtype tmtype;
  struct parameters tparameters;
  mfile tfile;
  pattern tpattern;
  patternlist tpatternlist;
  matchnode tmatchnode;
  matchcond tmatchcond;
  matchnodelist tmatchnodelist;
} YYSTYPE;
/* Line 1985 of glr.c.  */
#line 150 "parser.tab.h"
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE yylval;



