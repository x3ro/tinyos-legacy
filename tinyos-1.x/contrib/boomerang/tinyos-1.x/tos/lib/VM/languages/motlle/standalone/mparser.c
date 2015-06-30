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

/* This is the parser code for GLR (Generalized LR) parser. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <setjmp.h>

/* Identify Bison output.  */
#define YYBISON 1

/* Skeleton name.  */
#define YYSKELETON_NAME "glr.c"

/* Pure parsers.  */
#define YYPURE 0

/* Using locations.  */
#define YYLSP_NEEDED 0



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




/* Copy the first part of user declarations.  */
#line 22 "../standalone/parser.y"

#include "mudlle.h"
#include "mparser.h"
#include "utils.h"
#include "calloc.h"
#include "types.h"
#include "compile.h"
#include <stdlib.h>
#include <string.h>

#define __cplusplus
#  define yytrue 1
#  define yyfalse 0


/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 1
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

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
/* Line 188 of glr.c.  */
#line 202 "parser.tab.c"
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

#if ! defined (YYLTYPE) && ! defined (YYLTYPE_IS_DECLARED)
typedef struct YYLTYPE
{
  int first_line;
  int first_column;
  int last_line;
  int last_column;
} YYLTYPE;
# define YYLTYPE_IS_DECLARED 1
# define YYLTYPE_IS_TRIVIAL 1
#endif

/* Default (constant) values used for initialization for null
   right-hand sides.  Unlike the standard yacc.c template,
   here we set the default values of $$ and $@ to zeroed-out
   values.  Since the default value of these quantities is undefined,
   this behavior is technically correct. */
static YYSTYPE yyval_default;
static YYLTYPE yyloc_default;

/* Copy the second part of user declarations.  */
#line 116 "../standalone/parser.y"


#include "lexer.h"

static mfile parsed_code;
block_t parser_memory;

void yyerror(const char *s)
{
  log_error(lexloc, "%s", s);
}

static struct lstack {
  struct lstack *next;
  struct location l;
} *lstack;

static block_t line_memory;

static void lpush(location l)
{
  struct lstack *newp = allocate(line_memory, sizeof *newp);

  newp->next = lstack;
  lstack = newp;

  newp->l = l;
}

static void lpop(location *l)
{
  *l = lstack->l;
  lstack = lstack->next;
}

static component make_binary(unsigned int op, component arg1, component arg2)
{
  if (op == b_xor)
    return new_xor_component(parser_memory, arg1, arg2);
  return new_component(parser_memory, c_builtin, op, 2, arg1, arg2);
}

static component make_unary(unsigned int op, component arg)
{
  return new_component(parser_memory, c_builtin, op, 1, arg);
}

static component make_ref_set_increment(component exp0, component exp1, 
					int op, component exp2,
					int is_postfix)
{
    /* prefix:
     *  [
     *    | ~exp, ~ref |
     *    ~exp = <exp0>; ~ref = <exp1>;
     *    ~exp[~ref] = ~exp[~ref] <op> <exp2>;
     *  ]
     *
     * postfix:
     *  [
     *    | ~exp, ~ref, ~val |
     *    ~exp = <exp0>; ~ref = <exp1>;
     *    ~val = ~exp[~ref];
     *    ~exp[~ref] = ~val <op> <exp2>;
     *    ~val;
     *  ]
     */
    const char *expname, *refname;
    vlist vl = NULL;
    component val;
    clist cl = NULL;

    if (exp0->vclass == c_recall)
      expname = exp0->u.recall;
    else
      {
	expname = "~exp";
	vl = new_vlist(parser_memory, expname, stype_any, NULL, vl);
	cl = new_clist(parser_memory,
		       new_component(parser_memory, c_assign, expname, exp0),
		       cl);
      }
    if (exp1->vclass == c_recall)
      refname = exp1->u.recall;
    else
      {
	refname = "~ref";
	vl = new_vlist(parser_memory, refname, stype_any, NULL, vl);
	cl = new_clist(parser_memory,
		       new_component(parser_memory, c_assign, refname, exp1),
		       cl);

      }

    if (is_postfix)
      vl = new_vlist(parser_memory, "~val", stype_any, NULL,
		     vl);

    val = new_component(parser_memory, c_builtin, b_ref, 2,
			new_component(parser_memory, c_recall, expname),
			new_component(parser_memory, c_recall, refname));

    if (is_postfix)
      {
	cl = new_clist(parser_memory, 
		       new_component(parser_memory, c_assign, "~val", val),
		       cl);
	val = new_component(parser_memory, c_recall, "~val");
      }

    cl = new_clist(parser_memory,
		   new_component(parser_memory, c_builtin, b_set, 3, 
				 new_component(parser_memory, c_recall, expname),
				 new_component(parser_memory, c_recall, refname),
				 make_binary(op, val, exp2)),
		   cl);

    if (is_postfix)
      cl = new_clist(parser_memory,
		     new_component(parser_memory, c_recall, "~val"),
		     cl);

    return new_component(parser_memory, c_block,
			 new_codeblock(parser_memory,
				       vl,
				       reverse_clist(cl)));
}

static component make_function(mtype t, char *help, struct parameters parms,
			       component body)
{
  struct location l;
  function fn;

  lpop(&l);
  if (parms.varargs)
    fn = new_vfunction(parser_memory, t, help, parms.var, body, l);
  else
    fn = new_function(parser_memory, t, help, parms.args, body, l);

  return new_component(parser_memory, c_closure, fn);
}

static component make_function_decl(mtype t, char *name, char *help,
				    struct parameters parms, component body)
{
  component def = make_function(t, help, parms, body);
  vlist decl = new_vlist(parser_memory, name, stype_any, def, NULL);

  return new_component(parser_memory, c_decl, decl);  
}

void parser_init(void)
{
}

int yyparse();

mfile parse(block_t heap)
{
  int result;

  parser_memory = heap;
  line_memory = new_block();
  erred = FALSE;
  result = yyparse();
  free_block(line_memory);
  line_memory = parser_memory = NULL;

  return result == 0 && !erred ? parsed_code : NULL;
}

struct mkeyword {
  const char *name;
  mtype value;
};

static struct mkeyword types[] = {
  { "int", type_integer },
  { "float", type_float },
  { "string", type_string },
  { "vector", type_vector },
  { "pair", type_pair },
  { "symbol", type_symbol },
  { "table", type_table },
  { "function", type_function },
  { "list", stype_list },
  { "none", stype_none },
  { "any", stype_any },
  { "null", type_null }
};
#define NTYPES (sizeof types / sizeof(struct mkeyword))

mtype find_type(char *name)
{
  int i;

  for (i = 0; i < NTYPES; i++)
    if (!stricmp(name, types[i].name))
      return types[i].value;

  log_error(lexloc, "unknown type %s", name);
  return stype_none;
}

void set_vlist_types(vlist vars, mtype t)
{
  for (; vars; vars = vars->next)
    vars->type = t;
}



/* Line 216 of glr.c.  */
#line 443 "parser.tab.c"

#if ! defined (__cplusplus)
   typedef char bool;
#  define yytrue 1
#  define yyfalse 0
#endif

/*-----------------.
| GCC extensions.  |
`-----------------*/

#ifndef __attribute__
/* This feature is available in gcc versions 2.5 and later.  */
# if !defined (__GNUC__) || __GNUC__ < 2 || \
(__GNUC__ == 2 && __GNUC_MINOR__ < 5) || __STRICT_ANSI__
#  define __attribute__(Spec) /* empty */
# endif
#endif

#ifndef ATTRIBUTE_UNUSED
# define ATTRIBUTE_UNUSED __attribute__ ((__unused__))
#endif

/* YYFINAL -- State number of the termination state. */
#define YYFINAL  3
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   970

/* YYNTOKENS -- Number of terminals. */
#define YYNTOKENS  68
/* YYNNTS -- Number of nonterminals. */
#define YYNNTS  87
/* YYNRULES -- Number of rules. */
#define YYNRULES  208
/* YYNRULES -- Number of states. */
#define YYNSTATES  376
/* YYMAXRHS -- Maximum number of symbols on right-hand side of rule. */
#define YYMAXRHS 10

/* YYTRANSLATE(X) -- Bison symbol number corresponding to X.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   302

#define YYTRANSLATE(YYX) 						\
  ((YYX <= 0) ? YYEOF :							\
   (unsigned)(YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const unsigned char yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,    57,    50,     2,
      34,    64,    55,    53,    66,    54,    36,    56,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,    63,    62,
       2,     2,     2,     2,    67,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    32,     2,    61,    49,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    35,    48,    65,    58,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    33,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,    47,    51,
      52,    59,    60
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const unsigned short yyprhs[] =
{
       0,     0,     3,     4,     7,     9,    11,    13,    15,    17,
      18,    22,    24,    27,    29,    39,    50,    52,    53,    56,
      57,    60,    63,    64,    67,    68,    70,    73,    75,    76,
      78,    81,    83,    86,    88,    90,    93,    95,    97,    99,
     101,   103,   106,   108,   110,   112,   113,   117,   119,   121,
     123,   124,   127,   131,   133,   137,   141,   148,   155,   157,
     159,   161,   163,   165,   167,   169,   171,   178,   179,   182,
     190,   196,   204,   214,   223,   231,   233,   236,   237,   242,
     245,   249,   252,   254,   259,   264,   268,   271,   274,   278,
     282,   285,   286,   293,   294,   296,   300,   302,   303,   305,
     310,   314,   317,   319,   320,   322,   324,   328,   332,   336,
     340,   344,   348,   352,   356,   360,   364,   368,   372,   376,
     380,   384,   388,   392,   396,   400,   404,   407,   410,   413,
     416,   419,   425,   431,   433,   435,   437,   439,   441,   444,
     448,   452,   457,   462,   463,   465,   469,   471,   473,   476,
     478,   482,   485,   489,   493,   498,   501,   502,   505,   507,
     509,   511,   513,   514,   516,   518,   521,   523,   526,   530,
     532,   534,   536,   539,   541,   543,   545,   547,   550,   552,
     556,   558,   561,   562,   564,   565,   568,   573,   576,   581,
     585,   587,   589,   591,   593,   595,   599,   603,   607,   609,
     610,   617,   619,   621,   624,   626,   630,   632,   634
};

/* YYRHS -- A `-1'-separated list of the rules' RHS. */
static const short yyrhs[] =
{
      69,     0,    -1,    -1,    70,    71,    -1,    72,    -1,    77,
      -1,    76,    -1,    83,    -1,    90,    -1,    -1,    31,    73,
      74,    -1,    75,    -1,    75,    92,    -1,    92,    -1,    18,
      78,    79,    81,    82,    32,    83,    61,    85,    -1,    19,
      24,    79,    80,    81,    82,    32,    83,    61,    85,    -1,
      24,    -1,    -1,    20,   148,    -1,    -1,    21,   148,    -1,
      22,   148,    -1,    -1,    23,   148,    -1,    -1,    84,    -1,
      84,    87,    -1,    87,    -1,    -1,    62,    -1,    94,    86,
      -1,    89,    -1,    94,    87,    -1,    88,    -1,    96,    -1,
      90,    62,    -1,    62,    -1,   147,    -1,   149,    -1,   145,
      -1,    96,    -1,    90,    62,    -1,    62,    -1,   145,    -1,
      97,    -1,    -1,    30,    91,    92,    -1,    95,    -1,   125,
      -1,    90,    -1,    -1,    24,    63,    -1,   133,     8,    90,
      -1,   111,    -1,   143,     8,    90,    -1,   143,    28,    90,
      -1,   120,    32,    90,    61,     8,    90,    -1,   120,    32,
      90,    61,    28,    90,    -1,   119,    -1,    98,    -1,   101,
      -1,   102,    -1,   103,    -1,   110,    -1,   104,    -1,   100,
      -1,     4,    34,    90,    64,    86,    99,    -1,    -1,     5,
      86,    -1,     4,    34,    90,    64,    90,     5,    90,    -1,
       6,    34,    90,    64,    86,    -1,    17,    86,     6,    34,
      90,    64,    62,    -1,     7,    34,    93,    62,    93,    62,
      93,    64,    86,    -1,     7,    34,   147,    93,    62,    93,
      64,    86,    -1,    13,    34,    90,    64,    35,   105,    65,
      -1,   107,    -1,   105,   107,    -1,    -1,     4,    34,    90,
      64,    -1,   108,    83,    -1,    15,    63,    83,    -1,   109,
     108,    -1,   109,    -1,    14,   134,   106,    63,    -1,     9,
      24,    90,    62,    -1,     9,    24,    62,    -1,     9,    62,
      -1,    10,    62,    -1,    10,    24,    62,    -1,    11,    90,
      62,    -1,    11,    62,    -1,    -1,   117,     3,   112,   114,
     113,   151,    -1,    -1,    26,    -1,    34,   115,    64,    -1,
     144,    -1,    -1,   116,    -1,   116,    66,   118,   144,    -1,
     116,    66,   144,    -1,   118,   144,    -1,   144,    -1,    -1,
     118,    -1,    24,    -1,   119,    36,   119,    -1,   119,    37,
     119,    -1,   119,    39,   119,    -1,   119,    41,   119,    -1,
     119,    47,   119,    -1,   119,    46,   119,    -1,   119,    45,
     119,    -1,   119,    44,   119,    -1,   119,    43,   119,    -1,
     119,    42,   119,    -1,   119,    48,   119,    -1,   119,    49,
     119,    -1,   119,    50,   119,    -1,   119,    52,   119,    -1,
     119,    51,   119,    -1,   119,    53,   119,    -1,   119,    54,
     119,    -1,   119,    55,   119,    -1,   119,    56,   119,    -1,
     119,    57,   119,    -1,    54,   119,    -1,    60,   119,    -1,
      58,   119,    -1,    29,   143,    -1,   143,    29,    -1,    29,
     120,    32,    90,    61,    -1,   120,    32,    90,    61,    29,
      -1,   120,    -1,   122,    -1,   121,    -1,   143,    -1,   127,
      -1,    33,   125,    -1,    34,    90,    64,    -1,    34,   145,
      64,    -1,   120,    32,    90,    61,    -1,   120,    34,   123,
      64,    -1,    -1,   124,    -1,   124,    66,    90,    -1,    90,
      -1,   127,    -1,    33,   125,    -1,   142,    -1,    35,   131,
      65,    -1,    35,    65,    -1,    32,   129,    61,    -1,    32,
     129,    64,    -1,    34,   130,   126,    64,    -1,    34,    64,
      -1,    -1,    36,   125,    -1,   128,    -1,    25,    -1,    27,
      -1,    26,    -1,    -1,   130,    -1,   125,    -1,   130,   125,
      -1,   132,    -1,   131,   132,    -1,   128,     8,   125,    -1,
     140,    -1,   141,    -1,    90,    -1,    67,   135,    -1,   133,
      -1,    12,    -1,   143,    -1,   127,    -1,    66,   136,    -1,
     143,    -1,    34,    90,    64,    -1,   135,    -1,   137,   135,
      -1,    -1,   137,    -1,    -1,    36,   135,    -1,    34,   137,
     139,    64,    -1,    34,    64,    -1,    32,   138,    16,    61,
      -1,    32,   138,    61,    -1,    24,    -1,    53,    -1,    24,
      -1,    24,    -1,   146,    -1,    35,    83,    65,    -1,   118,
     153,    62,    -1,   148,    66,   144,    -1,   144,    -1,    -1,
     118,   143,   150,   114,   113,   152,    -1,    90,    -1,   145,
      -1,    90,    62,    -1,   145,    -1,   153,    66,   154,    -1,
     154,    -1,   144,    -1,   144,     8,    90,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const unsigned short yyrline[] =
{
       0,   331,   331,   331,   334,   335,   336,   339,   341,   343,
     343,   346,   349,   350,   352,   355,   359,   360,   363,   364,
     367,   370,   371,   374,   375,   377,   380,   381,   383,   383,
     386,   387,   390,   391,   394,   395,   396,   397,   398,   399,
     402,   403,   404,   405,   408,   409,   409,   410,   413,   416,
     417,   419,   422,   423,   424,   425,   431,   433,   436,   438,
     438,   438,   438,   438,   438,   440,   443,   452,   453,   456,
     461,   467,   473,   478,   486,   491,   492,   495,   496,   499,
     502,   507,   508,   511,   516,   518,   520,   522,   524,   526,
     528,   533,   533,   537,   538,   541,   542,   545,   546,   549,
     550,   551,   552,   555,   556,   559,   562,   563,   564,   565,
     566,   567,   568,   569,   570,   571,   572,   573,   574,   575,
     576,   577,   578,   579,   580,   581,   582,   583,   584,   585,
     594,   596,   603,   610,   613,   614,   615,   616,   617,   618,
     619,   622,   626,   630,   631,   634,   635,   638,   639,   640,
     641,   642,   643,   644,   645,   648,   651,   652,   655,   656,
     657,   660,   663,   664,   667,   668,   671,   672,   675,   681,
     682,   685,   686,   689,   690,   691,   692,   693,   696,   700,
     703,   704,   707,   708,   711,   712,   715,   719,   722,   725,
     730,   731,   734,   737,   740,   744,   749,   755,   757,   761,
     761,   765,   766,   769,   770,   773,   774,   777,   778
};
#endif

#if (YYDEBUG) || YYERROR_VERBOSE
/* YYTNME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals. */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "FUNCTION", "IF", "ELSE", "WHILE", "FOR", 
  "ASSIGN", "BREAK", "CONTINUE", "RETURN", "SINK", "SWITCH", "CASE", 
  "DEFAULT", "ELLIPSIS", "DO", "MODULE", "LIBRARY", "IMPORTS", "DEFINES", 
  "READS", "WRITES", "SYMBOL", "INTEGER", "STRING", "FLOAT", "OP_ASSIGN", 
  "INCREMENTER", "SCHEME", "SCHEMEFILE", "'['", "QUOTE", "'('", "'{'", 
  "'.'", "XOR", "OR", "SC_OR", "AND", "SC_AND", "GE", "GT", "LE", "LT", 
  "NE", "EQ", "'|'", "'^'", "'&'", "SHIFT_RIGHT", "SHIFT_LEFT", "'+'", 
  "'-'", "'*'", "'/'", "'%'", "'~'", "UMINUS", "NOT", "']'", "';'", "':'", 
  "')'", "'}'", "','", "'@'", "$accept", "start", "@1", "entry_types", 
  "simple", "@2", "scheme_file", "scheme_file1", "module", "library", 
  "optional_symbol", "imports", "defines", "reads", "writes", "stmt_list", 
  "stmt_list1", "optional_semi", "stmt", "decl_or_stmt", "decl_or_stmt1", 
  "stmt1", "expression", "@3", "scheme_expression", "optional_expression", 
  "label", "e0", "control_statement", "control_expression", "if", 
  "optional_else", "eif", "while", "dowhile", "for", "match", 
  "match_list", "opt_match_condition", "match_node", "match_patterns", 
  "match_pattern", "exit", "function_expression", "@4", "optional_help", 
  "parameters", "plist", "plist1", "optional_type", "type", "e1", "e2", 
  "array_ref", "function_call", "call_list", "call_list1", "constant", 
  "optional_constant_tail", "simple_constant", "string_constant", 
  "optional_constant_list", "constant_list", "table_entry_list", 
  "table_entry", "pattern", "pattern_case", "pattern_atom", 
  "pattern_atom_expr", "pattern_sequence", "opt_pattern_sequence", 
  "opt_pattern_list_tail", "pattern_list", "pattern_array", "anysymbol", 
  "variable", "variable_name", "code_block", "motlle_code_block", 
  "variable_decl", "variable_list", "function_decl", "@5", 
  "function_body1", "function_body2", "variable_init_list", 
  "variable_init", 0
};

#define yytname_size ((int) (sizeof (yytname) / sizeof (yytname[0])))
#endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const unsigned char yyr1[] =
{
       0,    68,    70,    69,    71,    71,    71,    72,    72,    73,
      72,    74,    75,    75,    76,    77,    78,    78,    79,    79,
      80,    81,    81,    82,    82,    83,    84,    84,    85,    85,
      86,    86,    87,    87,    88,    88,    88,    88,    88,    88,
      89,    89,    89,    89,    90,    91,    90,    90,    92,    93,
      93,    94,    95,    95,    95,    95,    95,    95,    95,    96,
      96,    96,    96,    96,    96,    97,    98,    99,    99,   100,
     101,   102,   103,   103,   104,   105,   105,   106,   106,   107,
     107,   108,   108,   109,   110,   110,   110,   110,   110,   110,
     110,   112,   111,   113,   113,   114,   114,   115,   115,   116,
     116,   116,   116,   117,   117,   118,   119,   119,   119,   119,
     119,   119,   119,   119,   119,   119,   119,   119,   119,   119,
     119,   119,   119,   119,   119,   119,   119,   119,   119,   119,
     119,   119,   119,   119,   120,   120,   120,   120,   120,   120,
     120,   121,   122,   123,   123,   124,   124,   125,   125,   125,
     125,   125,   125,   125,   125,   125,   126,   126,   127,   127,
     127,   128,   129,   129,   130,   130,   131,   131,   132,   133,
     133,   134,   134,   135,   135,   135,   135,   135,   136,   136,
     137,   137,   138,   138,   139,   139,   140,   140,   141,   141,
     142,   142,   143,   144,   145,   146,   147,   148,   148,   150,
     149,   151,   151,   152,   152,   153,   153,   154,   154
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const unsigned char yyr2[] =
{
       0,     2,     0,     2,     1,     1,     1,     1,     1,     0,
       3,     1,     2,     1,     9,    10,     1,     0,     2,     0,
       2,     2,     0,     2,     0,     1,     2,     1,     0,     1,
       2,     1,     2,     1,     1,     2,     1,     1,     1,     1,
       1,     2,     1,     1,     1,     0,     3,     1,     1,     1,
       0,     2,     3,     1,     3,     3,     6,     6,     1,     1,
       1,     1,     1,     1,     1,     1,     6,     0,     2,     7,
       5,     7,     9,     8,     7,     1,     2,     0,     4,     2,
       3,     2,     1,     4,     4,     3,     2,     2,     3,     3,
       2,     0,     6,     0,     1,     3,     1,     0,     1,     4,
       3,     2,     1,     0,     1,     1,     3,     3,     3,     3,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
       3,     3,     3,     3,     3,     3,     2,     2,     2,     2,
       2,     5,     5,     1,     1,     1,     1,     1,     2,     3,
       3,     4,     4,     0,     1,     3,     1,     1,     2,     1,
       3,     2,     3,     3,     4,     2,     0,     2,     1,     1,
       1,     1,     0,     1,     1,     2,     1,     2,     3,     1,
       1,     1,     2,     1,     1,     1,     1,     2,     1,     3,
       1,     2,     0,     1,     0,     2,     4,     2,     4,     3,
       1,     1,     1,     1,     1,     3,     3,     3,     1,     0,
       6,     1,     1,     2,     1,     3,     1,     1,     3
};

/* YYDPREC[RULE-NUM] -- Dynamic precedence of rule #RULE-NUM (0 if none). */
static const unsigned char yydprec[] =
{
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0
};

/* YYMERGER[RULE-NUM] -- Index of merging function for rule #RULE-NUM. */
static const unsigned char yymerger[] =
{
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0
};

/* YYDEFACT[S] -- default rule to reduce with in state S when YYTABLE
   doesn't specify something else to do.  Zero means the default is an
   error.  */
static const unsigned char yydefact[] =
{
       2,     0,   103,     1,     0,     0,     0,     0,     0,   103,
       0,   103,    17,     0,   192,   159,   161,   160,     0,    45,
       9,   182,     0,   103,   103,     0,     0,     0,    36,     3,
       4,     6,     5,     7,    25,    27,    33,     8,   103,    47,
      34,    44,    59,    65,    60,    61,    62,    64,    63,    53,
       0,   104,    58,   133,   135,   134,   137,   158,     0,   169,
     170,   136,    39,   194,    37,    38,   103,   103,    50,   103,
      86,     0,    87,     0,   192,    90,     0,   104,   103,    42,
       0,    31,     0,   103,    40,    43,    16,    19,    19,    51,
     192,   103,     0,   129,     0,     0,   174,     0,     0,   176,
     173,   180,   183,     0,   175,   190,   162,     0,     0,     0,
     191,   138,   147,   149,   187,     0,   137,   173,   184,   136,
       0,     0,     0,   126,   133,   136,   128,   127,    26,    35,
      32,    91,   193,   199,   207,     0,   206,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   103,   103,   103,
     103,   103,   130,     0,     0,    49,     0,   104,    50,    85,
       0,    88,   103,    89,     0,     0,    41,    30,     0,    22,
       0,   103,    46,    48,    10,    11,    13,   103,   177,   178,
     181,     0,   189,   164,     0,   163,   148,   155,   156,   151,
       0,     0,   166,   139,     0,     0,   140,   195,   103,     0,
       0,   103,   196,     0,   106,   107,   108,   109,   115,   114,
     113,   112,   111,   110,   116,   117,   118,   120,   119,   121,
     122,   123,   124,   125,     0,   146,     0,   144,    52,    54,
      55,   103,   103,    50,   193,     0,    84,     0,     0,   103,
     198,    18,     0,    24,     0,    22,     0,    12,     0,   188,
     152,   153,   165,     0,     0,     0,   150,   167,   185,   186,
       0,    97,    93,    96,    93,   208,   205,   141,   142,   103,
      67,     0,    70,     0,    50,   103,     0,     0,     0,    21,
       0,     0,    20,    24,   131,   179,   157,   154,   168,   141,
     193,     0,    98,     0,   102,    94,   103,   103,   103,   103,
     132,   145,   103,    66,   103,    50,     0,     0,   103,     0,
       0,    75,   103,    82,     0,   197,    23,   103,     0,    95,
       0,   101,   201,   202,    92,     0,   204,   200,    56,    57,
      68,    69,     0,   103,     0,   171,    77,   103,    74,    76,
      79,    81,    71,     0,   103,     0,   100,   203,   103,    73,
     172,     0,     0,    80,    28,     0,    99,    72,   103,    83,
      29,    14,    28,     0,    15,    78
};

/* YYPDEFGOTO[NTERM-NUM]. */
static const short yydefgoto[] =
{
      -1,     1,     2,    29,    30,    95,   184,   185,    31,    32,
      87,   179,   255,   253,   291,    33,    34,   371,    80,    35,
      36,    81,   122,    94,   182,   166,    38,    39,    40,    41,
      42,   313,    43,    44,    45,    46,    47,   320,   362,   321,
     322,   323,    48,    49,   209,   306,   272,   301,   302,    50,
      77,    52,    53,    54,    55,   236,   237,   183,   264,    56,
      57,   194,   195,   201,   202,    58,   346,   101,   188,   118,
     103,   205,    59,    60,   113,    61,   250,    62,    63,    64,
     251,    65,   210,   334,   337,   135,   136
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -216
static const short yypact[] =
{
    -216,    16,   530,  -216,    23,    68,    71,    29,    53,   620,
      77,   569,    27,    92,    25,  -216,  -216,  -216,   186,  -216,
    -216,   805,   497,   412,   608,   831,   831,   831,  -216,  -216,
    -216,  -216,  -216,  -216,   484,  -216,  -216,    46,   608,  -216,
    -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,
     118,   130,   851,     9,  -216,  -216,  -216,  -216,   152,  -216,
    -216,    34,  -216,  -216,  -216,  -216,   747,   747,   698,   659,
    -216,    99,  -216,   128,    24,  -216,   103,  -216,   747,  -216,
     166,  -216,   121,   569,  -216,  -216,  -216,   157,   157,  -216,
    -216,   735,    37,    85,   497,   497,  -216,   772,    26,  -216,
    -216,  -216,   805,    17,  -216,  -216,   497,   497,   816,    -4,
    -216,  -216,  -216,  -216,  -216,   114,    20,   152,   788,   682,
     120,   123,    46,  -216,   115,   162,  -216,  -216,  -216,  -216,
    -216,  -216,    70,  -216,   178,   -31,  -216,   831,   831,   831,
     831,   831,   831,   831,   831,   831,   831,   831,   831,   831,
     831,   831,   831,   831,   831,   831,   831,   747,   425,   747,
     747,   747,  -216,   129,   134,  -216,   139,   181,   698,  -216,
     145,  -216,   747,  -216,   144,   180,  -216,  -216,   181,   193,
     195,   747,  -216,  -216,  -216,   497,  -216,   747,  -216,  -216,
    -216,   161,  -216,  -216,    -6,   497,  -216,  -216,   265,  -216,
     215,    14,  -216,  -216,   805,   163,  -216,  -216,   747,    86,
      86,   747,  -216,   181,   851,   870,   887,   903,   913,   913,
     913,   913,   913,   913,   822,   822,   515,   314,   314,    88,
      88,  -216,  -216,  -216,   164,  -216,   165,   160,  -216,  -216,
    -216,   569,   569,   698,  -216,   171,  -216,   172,   200,   747,
    -216,   176,   181,   222,   181,   193,   177,  -216,   187,  -216,
    -216,  -216,  -216,   497,   188,   497,  -216,  -216,  -216,  -216,
     189,   232,   234,  -216,   238,  -216,  -216,    84,  -216,   747,
     253,    12,  -216,   204,   698,   747,   138,   203,   181,   176,
     181,   241,   176,   222,   116,  -216,  -216,  -216,  -216,   239,
     246,   210,   209,   181,  -216,  -216,   735,   735,   747,   747,
    -216,  -216,   569,  -216,   747,   698,   212,   276,   170,   224,
      15,  -216,   608,   274,   231,  -216,   176,   608,   262,  -216,
     232,  -216,  -216,  -216,  -216,   233,  -216,  -216,  -216,  -216,
    -216,  -216,   251,   569,   805,  -216,   299,   608,  -216,  -216,
    -216,  -216,  -216,   256,   608,   181,  -216,  -216,   569,  -216,
    -216,   286,   260,  -216,   263,   267,  -216,  -216,   747,  -216,
    -216,  -216,   263,   268,  -216,  -216
};

/* YYPGOTO[NTERM-NUM].  */
static const short yypgoto[] =
{
    -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,
    -216,   243,  -216,    69,    41,    -1,  -216,   -37,   -78,    80,
    -216,  -216,    -2,  -216,   -76,  -142,   -10,  -216,     7,  -216,
    -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,    22,
      13,  -216,  -216,  -216,  -216,    66,   133,  -216,  -216,  -216,
       0,   259,   236,  -216,  -216,  -216,  -216,    -8,  -216,    74,
     -94,  -216,   244,  -216,   143,    49,  -216,   -98,  -216,   328,
    -216,  -216,  -216,  -216,  -216,   -15,     8,     2,  -216,   283,
    -215,  -216,  -216,  -216,  -216,  -216,   142
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -193
static const short yytable[] =
{
      37,    83,    51,    93,   190,   177,   104,    76,   119,    82,
     125,   125,   125,    85,   111,   200,     3,   314,    84,   186,
     190,   115,    16,   121,    51,   120,   245,  -105,  -105,   318,
     319,   212,  -176,   191,    51,   213,   133,   289,    51,   292,
      16,   157,   160,   158,  -176,  -176,  -176,  -176,  -105,  -105,
      90,    86,  -137,    69,  -137,   260,  -137,    66,   261,   134,
     187,   199,   161,   162,   163,   164,   165,   170,   167,   181,
     100,   158,   117,    83,   176,   326,   174,    71,   192,   266,
     348,    82,   104,   189,  -137,    85,  -176,   104,    89,   115,
      84,    70,   308,   120,  -192,    99,   112,   116,   193,   196,
     193,   283,    67,   104,  -192,    68,   268,   200,   129,   257,
     244,    78,   309,   310,   128,    72,    88,  -136,   130,  -136,
     271,   131,   125,   125,   125,   125,   125,   125,   125,   125,
     125,   125,   125,   125,   125,   125,   125,   125,   125,   125,
     125,   125,   316,   154,   155,   156,   100,   208,  -141,   158,
    -141,   100,   318,   319,   132,   234,   235,   238,   239,   240,
     159,   171,   172,   280,   282,   173,   165,   100,   112,   112,
     247,    99,   175,   342,    73,   134,    99,   178,   203,   256,
     112,   112,   112,   176,   206,   258,   211,   262,   207,   104,
     262,   162,    99,   241,    74,    15,    16,    17,   242,    18,
      19,   243,    21,    22,    23,   244,   270,   246,   248,   275,
      90,    15,    16,    17,   249,   252,   254,   273,   273,    22,
      91,   134,   259,   265,    25,   277,   279,   269,    26,   278,
      27,    83,    83,   284,   340,   286,   285,   344,   294,   281,
      82,   165,   288,    85,    85,   290,   360,   287,    84,    84,
     299,   295,   297,   100,    92,   296,   300,   298,   312,   112,
     305,   124,   124,   124,   305,   359,   315,   324,   310,   112,
    -105,   303,   112,   327,   329,   330,   343,   311,    99,   304,
     367,   314,   165,   317,   123,   126,   127,   347,   318,   105,
      15,    16,    17,   352,   354,   357,   325,   106,   107,   108,
     109,   263,    83,   361,   332,   335,   338,   339,   333,   336,
      82,   331,   341,   165,    85,   358,   345,   364,   110,    84,
     368,   350,    51,   369,   293,   370,   353,    51,   372,   104,
     355,   180,   375,    83,   328,   374,   351,   112,   356,   112,
     307,    82,   349,   274,   267,    85,   363,    51,    83,   102,
      84,   168,   198,   365,    51,   276,    82,     0,     0,     0,
      85,     0,     0,   366,     0,    84,   373,   152,   153,   154,
     155,   156,     0,   124,   124,   124,   124,   124,   124,   124,
     124,   124,   124,   124,   124,   124,   124,   124,   124,   124,
     124,   124,   124,   100,     0,     0,   214,   215,   216,   217,
     218,   219,   220,   221,   222,   223,   224,   225,   226,   227,
     228,   229,   230,   231,   232,   233,    73,     0,    99,     0,
       0,     0,     0,     0,    96,     0,     0,     0,     0,    73,
       0,     0,     0,     0,     0,     0,    74,    15,    16,    17,
       0,    18,    19,     0,    21,    22,    23,    24,     0,    74,
      15,    16,    17,     0,    18,    19,     0,    21,    22,    23,
       0,     0,     0,     0,     0,     0,    25,     0,     0,     0,
      26,     0,    27,     0,     0,     0,   114,     0,    98,    25,
       0,     0,     0,    26,     0,    27,     0,  -103,     4,  -143,
       5,     6,     0,     7,     8,     9,     0,    10,     0,     0,
       0,    11,     0,     0,     0,     0,     0,     0,    14,    15,
      16,    17,     0,    18,    19,     0,    21,    22,    23,    24,
       0,   105,    15,    16,    17,     0,     0,     0,     0,   106,
     107,   108,   109,     0,     4,     0,     5,     6,    25,     7,
       8,     9,    26,    10,    27,     0,    28,    11,    12,    13,
     110,     0,     0,     0,    14,    15,    16,    17,     0,    18,
      19,    20,    21,    22,    23,    24,   150,   151,   152,   153,
     154,   155,   156,     4,     0,     5,     6,     0,     7,     8,
       9,     0,    10,     0,    25,     0,    11,     0,    26,     0,
      27,     0,    28,    14,    15,    16,    17,     0,    18,    19,
       0,    21,    22,    23,    24,     0,     0,     0,     0,     0,
       0,     0,     4,     0,     5,     6,     0,     7,     8,     9,
       0,    10,     0,    25,    73,    11,     0,    26,     0,    27,
       0,    79,    14,    15,    16,    17,     0,    18,    19,     0,
      21,    22,    23,    24,    74,    15,    16,    17,     0,    18,
      19,     0,    21,    22,    23,     0,     0,     0,     0,     0,
       0,     0,    25,    73,     0,     0,    26,     0,    27,     0,
      28,     0,     0,     0,    25,     0,     0,     0,    26,     0,
      27,     0,    75,    74,    15,    16,    17,     0,    18,    19,
     160,    21,    22,    23,  -175,     0,     0,     0,     0,     0,
       0,  -103,    73,     0,     0,     0,  -175,  -175,  -175,  -175,
     161,   162,     0,    25,  -136,     0,  -136,    26,  -136,    27,
       0,   169,    74,    15,    16,    17,     0,    18,    19,     0,
      21,    22,    23,     0,     0,     0,     0,     0,     0,    73,
       0,     0,     0,     0,     0,     0,  -136,     0,  -175,     0,
       0,    73,    25,     0,     0,     0,    26,     0,    27,    74,
      15,    16,    17,     0,    18,    19,     0,    21,    22,    23,
      24,    74,    15,    16,    17,     0,    18,    19,     0,    21,
      22,    23,     0,     0,    96,     0,     0,     0,     0,    25,
       0,     0,     0,    26,     0,    27,    90,    15,    16,    17,
      96,    25,     0,     0,    21,    26,    97,    27,     0,     0,
       0,     0,    90,    15,    16,    17,     0,    96,     0,     0,
      21,     0,    97,     0,   204,     0,     0,     0,     0,    90,
      15,    16,    17,     0,     0,     0,   114,    21,    98,    97,
     105,    15,    16,    17,     0,     0,     0,     0,   106,   107,
     108,   109,     0,     0,    98,    90,    15,    16,    17,     0,
      18,     0,     0,     0,    22,    91,     0,     0,     0,   110,
       0,    98,   149,   150,   151,   152,   153,   154,   155,   156,
     197,     0,     0,     0,     0,    25,     0,   137,   138,    26,
     139,    27,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,   151,   152,   153,   154,   155,   156,   139,
       0,   140,   141,   142,   143,   144,   145,   146,   147,   148,
     149,   150,   151,   152,   153,   154,   155,   156,   140,   141,
     142,   143,   144,   145,   146,   147,   148,   149,   150,   151,
     152,   153,   154,   155,   156,   141,   142,   143,   144,   145,
     146,   147,   148,   149,   150,   151,   152,   153,   154,   155,
     156,   147,   148,   149,   150,   151,   152,   153,   154,   155,
     156
};

/* YYCONFLP[YYPACT[STATE-NUM]] -- Pointer into YYCONFL of start of
   list of conflicting reductions corresponding to action entry for
   state STATE-NUM in yytable.  0 means no conflicts.  The list in
   yyconfl is terminated by a rule number of 0.  */
static const unsigned char yyconflp[] =
{
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     1,     0,
       0,     0,     3,     0,     5,     0,     7,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     9,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    23,     0,
      19,     0,     0,     0,    21,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    11,     0,    13,     0,    15,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    17,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0
};

/* YYCONFL[I] -- lists of conflicting rule numbers, each terminated by
   0, pointed into by YYCONFLP.  */
static const short yyconfl[] =
{
       0,   192,     0,   176,     0,   176,     0,   176,     0,   176,
       0,   175,     0,   175,     0,   175,     0,   175,     0,    93,
       0,    93,     0,    67,     0
};

static const short yycheck[] =
{
       2,    11,     2,    18,   102,    83,    21,     9,    23,    11,
      25,    26,    27,    11,    22,   109,     0,     5,    11,    95,
     118,    23,    26,    24,    24,    23,   168,     3,     3,    14,
      15,    62,    12,    16,    34,    66,    51,   252,    38,   254,
      26,    32,     8,    34,    24,    25,    26,    27,    24,    24,
      24,    24,    32,    24,    34,    61,    36,    34,    64,    51,
      34,    65,    28,    29,    66,    67,    68,    69,    68,    32,
      21,    34,    23,    83,    62,   290,    78,    24,    61,    65,
      65,    83,    97,    98,    64,    83,    66,   102,    63,    91,
      83,    62,     8,    91,    24,    21,    22,    23,   106,   107,
     108,   243,    34,   118,    34,    34,   204,   201,    62,   185,
      24,    34,    28,    29,    34,    62,    24,    32,    38,    34,
      34,     3,   137,   138,   139,   140,   141,   142,   143,   144,
     145,   146,   147,   148,   149,   150,   151,   152,   153,   154,
     155,   156,   284,    55,    56,    57,    97,    32,    32,    34,
      34,   102,    14,    15,    24,   157,   158,   159,   160,   161,
       8,    62,    34,   241,   242,    62,   168,   118,    94,    95,
     172,    97,     6,   315,     4,   167,   102,    20,    64,   181,
     106,   107,   108,    62,    64,   187,     8,   195,    65,   204,
     198,    29,   118,    64,    24,    25,    26,    27,    64,    29,
      30,    62,    32,    33,    34,    24,   208,    62,    64,   211,
      24,    25,    26,    27,    34,    22,    21,   209,   210,    33,
      34,   213,    61,     8,    54,    61,    66,    64,    58,    64,
      60,   241,   242,    62,   312,    35,    64,    67,    61,   241,
     242,   243,    66,   241,   242,    23,   344,   249,   241,   242,
      61,    64,    64,   204,    18,   263,    24,   265,     5,   185,
      26,    25,    26,    27,    26,   343,    62,    64,    29,   195,
      24,   271,   198,    32,    64,    66,    64,   279,   204,   271,
     358,     5,   284,   285,    25,    26,    27,    63,    14,    24,
      25,    26,    27,    62,    32,    62,   288,    32,    33,    34,
      35,    36,   312,     4,   306,   307,   308,   309,   306,   307,
     312,   303,   314,   315,   312,    64,   318,    61,    53,   312,
      34,   322,   322,    63,   255,    62,   327,   327,    61,   344,
     330,    88,    64,   343,   293,   372,   323,   263,   330,   265,
     274,   343,   320,   210,   201,   343,   347,   347,   358,    21,
     343,    68,   108,   354,   354,   213,   358,    -1,    -1,    -1,
     358,    -1,    -1,   355,    -1,   358,   368,    53,    54,    55,
      56,    57,    -1,   137,   138,   139,   140,   141,   142,   143,
     144,   145,   146,   147,   148,   149,   150,   151,   152,   153,
     154,   155,   156,   344,    -1,    -1,   137,   138,   139,   140,
     141,   142,   143,   144,   145,   146,   147,   148,   149,   150,
     151,   152,   153,   154,   155,   156,     4,    -1,   344,    -1,
      -1,    -1,    -1,    -1,    12,    -1,    -1,    -1,    -1,     4,
      -1,    -1,    -1,    -1,    -1,    -1,    24,    25,    26,    27,
      -1,    29,    30,    -1,    32,    33,    34,    35,    -1,    24,
      25,    26,    27,    -1,    29,    30,    -1,    32,    33,    34,
      -1,    -1,    -1,    -1,    -1,    -1,    54,    -1,    -1,    -1,
      58,    -1,    60,    -1,    -1,    -1,    64,    -1,    66,    54,
      -1,    -1,    -1,    58,    -1,    60,    -1,     3,     4,    64,
       6,     7,    -1,     9,    10,    11,    -1,    13,    -1,    -1,
      -1,    17,    -1,    -1,    -1,    -1,    -1,    -1,    24,    25,
      26,    27,    -1,    29,    30,    -1,    32,    33,    34,    35,
      -1,    24,    25,    26,    27,    -1,    -1,    -1,    -1,    32,
      33,    34,    35,    -1,     4,    -1,     6,     7,    54,     9,
      10,    11,    58,    13,    60,    -1,    62,    17,    18,    19,
      53,    -1,    -1,    -1,    24,    25,    26,    27,    -1,    29,
      30,    31,    32,    33,    34,    35,    51,    52,    53,    54,
      55,    56,    57,     4,    -1,     6,     7,    -1,     9,    10,
      11,    -1,    13,    -1,    54,    -1,    17,    -1,    58,    -1,
      60,    -1,    62,    24,    25,    26,    27,    -1,    29,    30,
      -1,    32,    33,    34,    35,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,     4,    -1,     6,     7,    -1,     9,    10,    11,
      -1,    13,    -1,    54,     4,    17,    -1,    58,    -1,    60,
      -1,    62,    24,    25,    26,    27,    -1,    29,    30,    -1,
      32,    33,    34,    35,    24,    25,    26,    27,    -1,    29,
      30,    -1,    32,    33,    34,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    54,     4,    -1,    -1,    58,    -1,    60,    -1,
      62,    -1,    -1,    -1,    54,    -1,    -1,    -1,    58,    -1,
      60,    -1,    62,    24,    25,    26,    27,    -1,    29,    30,
       8,    32,    33,    34,    12,    -1,    -1,    -1,    -1,    -1,
      -1,     3,     4,    -1,    -1,    -1,    24,    25,    26,    27,
      28,    29,    -1,    54,    32,    -1,    34,    58,    36,    60,
      -1,    62,    24,    25,    26,    27,    -1,    29,    30,    -1,
      32,    33,    34,    -1,    -1,    -1,    -1,    -1,    -1,     4,
      -1,    -1,    -1,    -1,    -1,    -1,    64,    -1,    66,    -1,
      -1,     4,    54,    -1,    -1,    -1,    58,    -1,    60,    24,
      25,    26,    27,    -1,    29,    30,    -1,    32,    33,    34,
      35,    24,    25,    26,    27,    -1,    29,    30,    -1,    32,
      33,    34,    -1,    -1,    12,    -1,    -1,    -1,    -1,    54,
      -1,    -1,    -1,    58,    -1,    60,    24,    25,    26,    27,
      12,    54,    -1,    -1,    32,    58,    34,    60,    -1,    -1,
      -1,    -1,    24,    25,    26,    27,    -1,    12,    -1,    -1,
      32,    -1,    34,    -1,    36,    -1,    -1,    -1,    -1,    24,
      25,    26,    27,    -1,    -1,    -1,    64,    32,    66,    34,
      24,    25,    26,    27,    -1,    -1,    -1,    -1,    32,    33,
      34,    35,    -1,    -1,    66,    24,    25,    26,    27,    -1,
      29,    -1,    -1,    -1,    33,    34,    -1,    -1,    -1,    53,
      -1,    66,    50,    51,    52,    53,    54,    55,    56,    57,
      64,    -1,    -1,    -1,    -1,    54,    -1,    36,    37,    58,
      39,    60,    41,    42,    43,    44,    45,    46,    47,    48,
      49,    50,    51,    52,    53,    54,    55,    56,    57,    39,
      -1,    41,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    42,    43,    44,    45,    46,
      47,    48,    49,    50,    51,    52,    53,    54,    55,    56,
      57,    48,    49,    50,    51,    52,    53,    54,    55,    56,
      57
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const unsigned char yystos[] =
{
       0,    69,    70,     0,     4,     6,     7,     9,    10,    11,
      13,    17,    18,    19,    24,    25,    26,    27,    29,    30,
      31,    32,    33,    34,    35,    54,    58,    60,    62,    71,
      72,    76,    77,    83,    84,    87,    88,    90,    94,    95,
      96,    97,    98,   100,   101,   102,   103,   104,   110,   111,
     117,   118,   119,   120,   121,   122,   127,   128,   133,   140,
     141,   143,   145,   146,   147,   149,    34,    34,    34,    24,
      62,    24,    62,     4,    24,    62,    90,   118,    34,    62,
      86,    89,    90,    94,    96,   145,    24,    78,    24,    63,
      24,    34,   120,   143,    91,    73,    12,    34,    66,   127,
     133,   135,   137,   138,   143,    24,    32,    33,    34,    35,
      53,   125,   127,   142,    64,    90,   127,   133,   137,   143,
     145,    83,    90,   119,   120,   143,   119,   119,    87,    62,
      87,     3,    24,   143,   144,   153,   154,    36,    37,    39,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    32,    34,     8,
       8,    28,    29,    90,    90,    90,    93,   118,   147,    62,
      90,    62,    34,    62,    90,     6,    62,    86,    20,    79,
      79,    32,    92,   125,    74,    75,    92,    34,   136,   143,
     135,    16,    61,   125,   129,   130,   125,    64,   130,    65,
     128,   131,   132,    64,    36,   139,    64,    65,    32,   112,
     150,     8,    62,    66,   119,   119,   119,   119,   119,   119,
     119,   119,   119,   119,   119,   119,   119,   119,   119,   119,
     119,   119,   119,   119,    90,    90,   123,   124,    90,    90,
      90,    64,    64,    62,    24,    93,    62,    90,    64,    34,
     144,   148,    22,    81,    21,    80,    90,    92,    90,    61,
      61,    64,   125,    36,   126,     8,    65,   132,   135,    64,
      90,    34,   114,   144,   114,    90,   154,    61,    64,    66,
      86,    90,    86,    93,    62,    64,    35,    90,    66,   148,
      23,    82,   148,    81,    61,    64,   125,    64,   125,    61,
      24,   115,   116,   118,   144,    26,   113,   113,     8,    28,
      29,    90,     5,    99,     5,    62,    93,    90,    14,    15,
     105,   107,   108,   109,    64,   144,   148,    32,    82,    64,
      66,   144,    90,   145,   151,    90,   145,   152,    90,    90,
      86,    90,    93,    64,    67,    90,   134,    63,    65,   107,
      83,   108,    62,    83,    32,   118,   144,    62,    64,    86,
     135,     4,   106,    83,    61,    83,   144,    86,    34,    63,
      62,    85,    61,    90,    85,    64
};


/* Prevent warning if -Wmissing-prototypes.  */
int yyparse (void);

/* Error token number */
#define YYTERROR 1

/* YYLLOC_DEFAULT -- Compute the default location (before the actions
   are run).  */

#define YYRHSLOC(yyRhs,YYK) (yyRhs[YYK].yystate.yyloc)

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(yyCurrent, yyRhs, YYN)			\
  yyCurrent.first_line   = YYRHSLOC(yyRhs,1).first_line;	\
  yyCurrent.first_column = YYRHSLOC(yyRhs,1).first_column;	\
  yyCurrent.last_line    = YYRHSLOC(yyRhs,YYN).last_line;	\
  yyCurrent.last_column  = YYRHSLOC(yyRhs,YYN).last_column;
#endif

/* YYLEX -- calling `yylex' with the right arguments.  */
#define YYLEX yylex ()

YYSTYPE yylval;

YYLTYPE yylloc;

int yynerrs;
int yychar;

static const int YYEOF = 0;
static const int YYEMPTY = -2;

typedef enum { yyok, yyaccept, yyabort, yyerr } YYRESULTTAG;

#define YYCHK(YYE)							     \
   do { YYRESULTTAG yyflag = YYE; if (yyflag != yyok) return yyflag; } 	     \
   while (0)

#if YYDEBUG

#if ! defined (YYFPRINTF)
#  define YYFPRINTF fprintf
#endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (0)

/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

static void
yysymprint (FILE *yyoutput, int yytype, YYSTYPE *yyvaluep)
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  if (yytype < YYNTOKENS)
    {
      YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
# ifdef YYPRINT
      YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# endif
    }
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  switch (yytype)
    {
      default:
        break;
    }
  YYFPRINTF (yyoutput, ")");
}


# define YYDSYMPRINT(Args)			\
do {						\
  if (yydebug)					\
    yysymprint Args;				\
} while (0)

# define YYDSYMPRINTF(Title, Token, Value, Location)		\
do {								\
  if (yydebug)							\
    {								\
      YYFPRINTF (stderr, "%s ", Title);				\
      yysymprint (stderr, 					\
                  Token, Value);	\
      YYFPRINTF (stderr, "\n");					\
    }								\
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;

#else /* !YYDEBUG */

  /* Avoid empty `if' bodies.  */
# define YYDPRINTF(Args)
# define YYDSYMPRINT(Args)
# define YYDSYMPRINTF(Title, Token, Value, Location)

#endif /* !YYDEBUG */

/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   SIZE_MAX < YYMAXDEPTH * sizeof (GLRStackItem)
   evaluated with infinite-precision integer arithmetic.  */

#if YYMAXDEPTH == 0
# undef YYMAXDEPTH
#endif

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif

/* Minimum number of free items on the stack allowed after an
   allocation.  This is to allow allocation and initialization
   to be completed by functions that call expandGLRStack before the
   stack is expanded, thus insuring that all necessary pointers get
   properly redirected to new data. */
#define YYHEADROOM 2

#if (! defined (YYSTACKEXPANDABLE) \
     && (! defined (__cplusplus) \
	 || (YYSTYPE_IS_TRIVIAL)))
#define YYSTACKEXPANDABLE 1
#else
#define YYSTACKEXPANDABLE 0
#endif

/** State numbers, as in LALR(1) machine */
typedef int yyStateNum;

/** Rule numbers, as in LALR(1) machine */
typedef int yyRuleNum;

/** Grammar symbol */
typedef short yySymbol;

/** Item references, as in LALR(1) machine */
typedef short yyItemNum;

typedef struct yyGLRState yyGLRState;
typedef struct yySemanticOption yySemanticOption;
typedef union yyGLRStackItem yyGLRStackItem;
typedef struct yyGLRStack yyGLRStack;
typedef struct yyGLRStateSet yyGLRStateSet;

struct yyGLRState {
  bool yyisState;
  bool yyresolved;
  yyStateNum yylrState;
  yyGLRState* yypred;
  size_t yyposn;
  union {
    yySemanticOption* yyfirstVal;
    YYSTYPE yysval;
  } yysemantics;
  YYLTYPE yyloc;
};

struct yyGLRStateSet {
  yyGLRState** yystates;
  size_t yysize, yycapacity;
};

struct yySemanticOption {
  bool yyisState;
  yyRuleNum yyrule;
  yyGLRState* yystate;
  yySemanticOption* yynext;
};

union yyGLRStackItem {
  yyGLRState yystate;
  yySemanticOption yyoption;
};

struct yyGLRStack {
  int yyerrflag;
  int yyerrState;

  yySymbol* yytokenp;
  jmp_buf yyexception_buffer;
  yyGLRStackItem* yyitems;
  yyGLRStackItem* yynextFree;
  int yyspaceLeft;
  yyGLRState* yysplitPoint;
  yyGLRState* yylastDeleted;
  yyGLRStateSet yytops;
};

static void yyinitGLRStack (yyGLRStack* yystack, size_t yysize);
static void yyexpandGLRStack (yyGLRStack* yystack);
static void yyfreeGLRStack (yyGLRStack* yystack);

static void
yyFail (yyGLRStack* yystack, const char* yyformat, ...)
{
  yystack->yyerrflag = 1;
  if (yyformat != NULL)
    {
      char yymsg[256];
      va_list yyap;
      va_start (yyap, yyformat);
      vsprintf (yymsg, yyformat, yyap);
      yyerror (yymsg);
    }
  longjmp (yystack->yyexception_buffer, 1);
}

#if YYDEBUG || YYERROR_VERBOSE
/** A printable representation of TOKEN.  Valid until next call to
 *  tokenName. */
static inline const char*
yytokenName (yySymbol yytoken)
{
  return yytname[yytoken];
}
#endif

/** Perform user action for rule number YYN, with RHS length YYRHSLEN,
 *  and top stack item YYVSP.  YYLVALP points to place to put semantic
 *  value ($$), and yylocp points to place for location information
 *  (@$). Returns yyok for normal return, yyaccept for YYACCEPT,
 *  yyerr for YYERROR, yyabort for YYABORT. */
static YYRESULTTAG
yyuserAction (yyRuleNum yyn, int yyrhslen, yyGLRStackItem* yyvsp,
	      YYSTYPE* yyvalp, YYLTYPE* yylocp, yyGLRStack* yystack
              )
{
  /* Avoid `unused' warnings in there are no $n. */
  (void) yystack;

  if (yyrhslen == 0)
    {
      *yyvalp = yyval_default;
      *yylocp = yyloc_default;
    }
  else
    {
      *yyvalp = yyvsp[1-yyrhslen].yystate.yysemantics.yysval;
      *yylocp = yyvsp[1-yyrhslen].yystate.yyloc;
    }
# undef yyerrok
# define yyerrok (yystack->yyerrState = 0)
# undef YYACCEPT
# define YYACCEPT return yyaccept
# undef YYABORT
# define YYABORT return yyabort
# undef YYERROR
# define YYERROR return yyerr
# undef YYRECOVERING
# define YYRECOVERING (yystack->yyerrState != 0)
# undef yyclearin
# define yyclearin (yychar = *(yystack->yytokenp) = YYEMPTY)
# undef YYBACKUP
# define YYBACKUP(Token, Value)						     \
  do {									     \
    yyerror ("syntax error: cannot back up");		     \
    YYERROR;								     \
  } while (0)


   switch (yyn)
     {
         case 2:
#line 331 "../standalone/parser.y"
    { lstack = NULL; ;}
    break;

  case 3:
#line 331 "../standalone/parser.y"
    { parsed_code = yyvsp[0].yystate.yysemantics.yysval.tfile; ;}
    break;

  case 7:
#line 340 "../standalone/parser.y"
    { (*yyvalp).tfile = new_file(parser_memory, f_plain, NULL, NULL, NULL, NULL, NULL, yyvsp[0].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 8:
#line 342 "../standalone/parser.y"
    { (*yyvalp).tfile = new_file(parser_memory, f_plain, NULL, NULL, NULL, NULL, NULL, new_clist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tcomponent, NULL)); ;}
    break;

  case 9:
#line 343 "../standalone/parser.y"
    { scheme_lexing(); ;}
    break;

  case 10:
#line 344 "../standalone/parser.y"
    { (*yyvalp).tfile = new_file(parser_memory, f_plain, NULL, NULL, NULL, NULL, NULL, yyvsp[0].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 11:
#line 346 "../standalone/parser.y"
    { (*yyvalp).tclist = reverse_clist(yyvsp[0].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 12:
#line 349 "../standalone/parser.y"
    { (*yyvalp).tclist = new_clist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tcomponent, yyvsp[-1].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 13:
#line 350 "../standalone/parser.y"
    { (*yyvalp).tclist = new_clist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tcomponent, NULL); ;}
    break;

  case 14:
#line 353 "../standalone/parser.y"
    { (*yyvalp).tfile = new_file(parser_memory, f_module, yyvsp[-7].yystate.yysemantics.yysval.symbol, yyvsp[-6].yystate.yysemantics.yysval.tvlist, NULL, yyvsp[-5].yystate.yysemantics.yysval.tvlist, yyvsp[-4].yystate.yysemantics.yysval.tvlist, yyvsp[-2].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 15:
#line 356 "../standalone/parser.y"
    { (*yyvalp).tfile = new_file(parser_memory, f_library, yyvsp[-8].yystate.yysemantics.yysval.symbol, yyvsp[-7].yystate.yysemantics.yysval.tvlist, yyvsp[-6].yystate.yysemantics.yysval.tvlist, yyvsp[-5].yystate.yysemantics.yysval.tvlist, yyvsp[-4].yystate.yysemantics.yysval.tvlist, yyvsp[-2].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 17:
#line 360 "../standalone/parser.y"
    { (*yyvalp).symbol = NULL; ;}
    break;

  case 18:
#line 363 "../standalone/parser.y"
    { (*yyvalp).tvlist = yyvsp[0].yystate.yysemantics.yysval.tvlist; ;}
    break;

  case 19:
#line 364 "../standalone/parser.y"
    { (*yyvalp).tvlist = NULL; ;}
    break;

  case 20:
#line 367 "../standalone/parser.y"
    { (*yyvalp).tvlist = yyvsp[0].yystate.yysemantics.yysval.tvlist; ;}
    break;

  case 21:
#line 370 "../standalone/parser.y"
    { (*yyvalp).tvlist = yyvsp[0].yystate.yysemantics.yysval.tvlist; ;}
    break;

  case 22:
#line 371 "../standalone/parser.y"
    { (*yyvalp).tvlist = NULL; ;}
    break;

  case 23:
#line 374 "../standalone/parser.y"
    { (*yyvalp).tvlist = yyvsp[0].yystate.yysemantics.yysval.tvlist; ;}
    break;

  case 24:
#line 375 "../standalone/parser.y"
    { (*yyvalp).tvlist = NULL; ;}
    break;

  case 25:
#line 377 "../standalone/parser.y"
    { (*yyvalp).tclist = reverse_clist(yyvsp[0].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 26:
#line 380 "../standalone/parser.y"
    { (*yyvalp).tclist = new_clist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tcomponent, yyvsp[-1].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 27:
#line 381 "../standalone/parser.y"
    { (*yyvalp).tclist = new_clist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tcomponent, NULL); ;}
    break;

  case 30:
#line 386 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_labeled, yyvsp[-1].yystate.yysemantics.yysval.symbol, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 32:
#line 390 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_labeled, yyvsp[-1].yystate.yysemantics.yysval.symbol, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 35:
#line 395 "../standalone/parser.y"
    { (*yyvalp).tcomponent = yyvsp[-1].yystate.yysemantics.yysval.tcomponent; ;}
    break;

  case 36:
#line 396 "../standalone/parser.y"
    { (*yyvalp).tcomponent = component_undefined; ;}
    break;

  case 41:
#line 403 "../standalone/parser.y"
    { (*yyvalp).tcomponent = yyvsp[-1].yystate.yysemantics.yysval.tcomponent; ;}
    break;

  case 42:
#line 404 "../standalone/parser.y"
    { (*yyvalp).tcomponent = component_undefined; ;}
    break;

  case 45:
#line 409 "../standalone/parser.y"
    { scheme_lexing(); ;}
    break;

  case 46:
#line 409 "../standalone/parser.y"
    { normal_lexing(); (*yyvalp).tcomponent = yyvsp[0].yystate.yysemantics.yysval.tcomponent; ;}
    break;

  case 48:
#line 413 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_scheme, yyvsp[0].yystate.yysemantics.yysval.tconstant); ;}
    break;

  case 50:
#line 417 "../standalone/parser.y"
    { (*yyvalp).tcomponent = NULL; ;}
    break;

  case 51:
#line 419 "../standalone/parser.y"
    { (*yyvalp).symbol = yyvsp[-1].yystate.yysemantics.yysval.symbol; ;}
    break;

  case 52:
#line 422 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_pattern_component(parser_memory, yyvsp[-2].yystate.yysemantics.yysval.tpattern, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 54:
#line 424 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_assign, yyvsp[-2].yystate.yysemantics.yysval.symbol, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 55:
#line 425 "../standalone/parser.y"
    {
      (*yyvalp).tcomponent = new_component(parser_memory, c_assign,
			 yyvsp[-2].yystate.yysemantics.yysval.symbol, make_binary(yyvsp[-1].yystate.yysemantics.yysval.operator,
					 new_component(parser_memory, c_recall, yyvsp[-2].yystate.yysemantics.yysval.symbol),
					 yyvsp[0].yystate.yysemantics.yysval.tcomponent));
  ;}
    break;

  case 56:
#line 432 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_builtin, b_set, 3, yyvsp[-5].yystate.yysemantics.yysval.tcomponent, yyvsp[-3].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 57:
#line 433 "../standalone/parser.y"
    {
    (*yyvalp).tcomponent = make_ref_set_increment(yyvsp[-5].yystate.yysemantics.yysval.tcomponent, yyvsp[-3].yystate.yysemantics.yysval.tcomponent, yyvsp[-1].yystate.yysemantics.yysval.operator, yyvsp[0].yystate.yysemantics.yysval.tcomponent, 0);
  ;}
    break;

  case 66:
#line 444 "../standalone/parser.y"
    {
      if (yyvsp[0].yystate.yysemantics.yysval.tcomponent)
        (*yyvalp).tcomponent = new_component(parser_memory, c_builtin, b_ifelse, 3, yyvsp[-3].yystate.yysemantics.yysval.tcomponent, yyvsp[-1].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent);
      else
        (*yyvalp).tcomponent = new_component(parser_memory, c_builtin, b_if, 2, yyvsp[-3].yystate.yysemantics.yysval.tcomponent, yyvsp[-1].yystate.yysemantics.yysval.tcomponent);
    ;}
    break;

  case 67:
#line 452 "../standalone/parser.y"
    { (*yyvalp).tcomponent = NULL; ;}
    break;

  case 68:
#line 453 "../standalone/parser.y"
    { (*yyvalp).tcomponent = yyvsp[0].yystate.yysemantics.yysval.tcomponent; ;}
    break;

  case 69:
#line 456 "../standalone/parser.y"
    {
    (*yyvalp).tcomponent = new_component(parser_memory, c_builtin, b_ifelse, 3, yyvsp[-4].yystate.yysemantics.yysval.tcomponent, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent);
  ;}
    break;

  case 70:
#line 462 "../standalone/parser.y"
    {
      (*yyvalp).tcomponent = new_component(parser_memory, c_builtin, b_while, 2, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent);
    ;}
    break;

  case 71:
#line 468 "../standalone/parser.y"
    {
      (*yyvalp).tcomponent = new_component(parser_memory, c_builtin, b_dowhile, 2, yyvsp[-5].yystate.yysemantics.yysval.tcomponent, yyvsp[-2].yystate.yysemantics.yysval.tcomponent);
    ;}
    break;

  case 72:
#line 475 "../standalone/parser.y"
    {
      (*yyvalp).tcomponent = new_component(parser_memory, c_builtin, b_for, 4, yyvsp[-6].yystate.yysemantics.yysval.tcomponent, yyvsp[-4].yystate.yysemantics.yysval.tcomponent, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent);
    ;}
    break;

  case 73:
#line 480 "../standalone/parser.y"
    {
      (*yyvalp).tcomponent = new_component(parser_memory, c_builtin, b_for, 4, yyvsp[-5].yystate.yysemantics.yysval.tcomponent, yyvsp[-4].yystate.yysemantics.yysval.tcomponent, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent);
    ;}
    break;

  case 74:
#line 486 "../standalone/parser.y"
    {
    (*yyvalp).tcomponent = new_match_component(parser_memory, yyvsp[-4].yystate.yysemantics.yysval.tcomponent, yyvsp[-1].yystate.yysemantics.yysval.tmatchnodelist);
  ;}
    break;

  case 75:
#line 491 "../standalone/parser.y"
    { (*yyvalp).tmatchnodelist = new_match_list(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tmatchnode, NULL); ;}
    break;

  case 76:
#line 492 "../standalone/parser.y"
    { (*yyvalp).tmatchnodelist = new_match_list(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tmatchnode, yyvsp[-1].yystate.yysemantics.yysval.tmatchnodelist); ;}
    break;

  case 77:
#line 495 "../standalone/parser.y"
    { (*yyvalp).tcomponent = NULL; ;}
    break;

  case 78:
#line 496 "../standalone/parser.y"
    { (*yyvalp).tcomponent = yyvsp[-1].yystate.yysemantics.yysval.tcomponent; ;}
    break;

  case 79:
#line 499 "../standalone/parser.y"
    {
    (*yyvalp).tmatchnode = new_matchnode(parser_memory, yyvsp[-1].yystate.yysemantics.yysval.tmatchcond, yyvsp[0].yystate.yysemantics.yysval.tclist); 
  ;}
    break;

  case 80:
#line 502 "../standalone/parser.y"
    {
    (*yyvalp).tmatchnode = new_matchnode(parser_memory, NULL, yyvsp[0].yystate.yysemantics.yysval.tclist);
  ;}
    break;

  case 81:
#line 507 "../standalone/parser.y"
    { yyvsp[-1].yystate.yysemantics.yysval.tmatchcond->next = yyvsp[0].yystate.yysemantics.yysval.tmatchcond; (*yyvalp).tmatchcond = yyvsp[-1].yystate.yysemantics.yysval.tmatchcond; ;}
    break;

  case 83:
#line 511 "../standalone/parser.y"
    {
    (*yyvalp).tmatchcond = new_matchcond(parser_memory, yyvsp[-2].yystate.yysemantics.yysval.tpattern, yyvsp[-1].yystate.yysemantics.yysval.tcomponent, NULL);
  ;}
    break;

  case 84:
#line 516 "../standalone/parser.y"
    { 
    (*yyvalp).tcomponent = new_component(parser_memory, c_exit, yyvsp[-2].yystate.yysemantics.yysval.symbol, yyvsp[-1].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 85:
#line 518 "../standalone/parser.y"
    { 
    (*yyvalp).tcomponent = new_component(parser_memory, c_exit, yyvsp[-1].yystate.yysemantics.yysval.symbol, component_undefined); ;}
    break;

  case 86:
#line 520 "../standalone/parser.y"
    { 
    (*yyvalp).tcomponent = new_component(parser_memory, c_exit, NULL, component_undefined); ;}
    break;

  case 87:
#line 522 "../standalone/parser.y"
    { 
    (*yyvalp).tcomponent = new_component(parser_memory, c_continue, NULL); ;}
    break;

  case 88:
#line 524 "../standalone/parser.y"
    { 
    (*yyvalp).tcomponent = new_component(parser_memory, c_continue, yyvsp[-1].yystate.yysemantics.yysval.symbol); ;}
    break;

  case 89:
#line 526 "../standalone/parser.y"
    { 
    (*yyvalp).tcomponent = new_component(parser_memory, c_exit, "<return>", yyvsp[-1].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 90:
#line 528 "../standalone/parser.y"
    { 
    (*yyvalp).tcomponent = new_component(parser_memory, c_exit, "<return>", component_undefined); ;}
    break;

  case 91:
#line 533 "../standalone/parser.y"
    { lpush(lexloc); ;}
    break;

  case 92:
#line 534 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_function(yyvsp[-5].yystate.yysemantics.yysval.tmtype, yyvsp[-1].yystate.yysemantics.yysval.string, yyvsp[-2].yystate.yysemantics.yysval.tparameters, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 93:
#line 537 "../standalone/parser.y"
    { (*yyvalp).string = NULL; ;}
    break;

  case 95:
#line 541 "../standalone/parser.y"
    { (*yyvalp).tparameters.varargs = FALSE; (*yyvalp).tparameters.args = yyvsp[-1].yystate.yysemantics.yysval.tvlist; ;}
    break;

  case 96:
#line 542 "../standalone/parser.y"
    { (*yyvalp).tparameters.varargs = TRUE; (*yyvalp).tparameters.var = yyvsp[0].yystate.yysemantics.yysval.symbol; ;}
    break;

  case 97:
#line 545 "../standalone/parser.y"
    { (*yyvalp).tvlist = NULL; ;}
    break;

  case 98:
#line 546 "../standalone/parser.y"
    { (*yyvalp).tvlist = reverse_vlist(yyvsp[0].yystate.yysemantics.yysval.tvlist); ;}
    break;

  case 99:
#line 549 "../standalone/parser.y"
    { (*yyvalp).tvlist = new_vlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.symbol, yyvsp[-1].yystate.yysemantics.yysval.tmtype, NULL, yyvsp[-3].yystate.yysemantics.yysval.tvlist); ;}
    break;

  case 100:
#line 550 "../standalone/parser.y"
    { (*yyvalp).tvlist = new_vlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.symbol, stype_any, NULL, yyvsp[-2].yystate.yysemantics.yysval.tvlist); ;}
    break;

  case 101:
#line 551 "../standalone/parser.y"
    { (*yyvalp).tvlist = new_vlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.symbol, yyvsp[-1].yystate.yysemantics.yysval.tmtype, NULL, NULL); ;}
    break;

  case 102:
#line 552 "../standalone/parser.y"
    { (*yyvalp).tvlist = new_vlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.symbol, stype_any, NULL, NULL); ;}
    break;

  case 103:
#line 555 "../standalone/parser.y"
    { (*yyvalp).tmtype = stype_any; ;}
    break;

  case 105:
#line 559 "../standalone/parser.y"
    { (*yyvalp).tmtype = find_type(yyvsp[0].yystate.yysemantics.yysval.symbol); ;}
    break;

  case 106:
#line 562 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_cons, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 107:
#line 563 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_xor, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 108:
#line 564 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_sc_or, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 109:
#line 565 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_sc_and, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 110:
#line 566 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_eq, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 111:
#line 567 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_ne, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 112:
#line 568 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_lt, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 113:
#line 569 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_le, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 114:
#line 570 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_gt, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 115:
#line 571 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_ge, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 116:
#line 572 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_bitor, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 117:
#line 573 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_bitxor, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 118:
#line 574 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_bitand, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 119:
#line 575 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_shift_left, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 120:
#line 576 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_shift_right, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 121:
#line 577 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_add, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 122:
#line 578 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_subtract, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 123:
#line 579 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_multiply, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 124:
#line 580 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_divide, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 125:
#line 581 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_binary(b_remainder, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 126:
#line 582 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_unary(b_negate, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 127:
#line 583 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_unary(b_not, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 128:
#line 584 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_unary(b_bitnot, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 129:
#line 585 "../standalone/parser.y"
    {
    (*yyvalp).tcomponent = new_component
      (parser_memory, c_assign, 
       yyvsp[0].yystate.yysemantics.yysval.symbol, 
       make_binary(yyvsp[-1].yystate.yysemantics.yysval.operator,
		   new_component(parser_memory, c_recall, yyvsp[0].yystate.yysemantics.yysval.symbol),
		   new_component(parser_memory, c_constant,
				 new_constant(parser_memory, cst_int, 1))));
  ;}
    break;

  case 130:
#line 594 "../standalone/parser.y"
    { 
    (*yyvalp).tcomponent = new_postfix_inc_component(parser_memory, yyvsp[-1].yystate.yysemantics.yysval.symbol, yyvsp[0].yystate.yysemantics.yysval.operator); ;}
    break;

  case 131:
#line 596 "../standalone/parser.y"
    {
    (*yyvalp).tcomponent = make_ref_set_increment
      (yyvsp[-3].yystate.yysemantics.yysval.tcomponent, yyvsp[-1].yystate.yysemantics.yysval.tcomponent, yyvsp[-4].yystate.yysemantics.yysval.operator,
       new_component(parser_memory, c_constant,
		     new_constant(parser_memory, cst_int, 1)),
       0);
  ;}
    break;

  case 132:
#line 603 "../standalone/parser.y"
    {
    (*yyvalp).tcomponent = make_ref_set_increment
      (yyvsp[-4].yystate.yysemantics.yysval.tcomponent, yyvsp[-2].yystate.yysemantics.yysval.tcomponent, yyvsp[0].yystate.yysemantics.yysval.operator,
       new_component(parser_memory, c_constant,
		     new_constant(parser_memory, cst_int, 1)),
       1);
  ;}
    break;

  case 136:
#line 615 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_recall, yyvsp[0].yystate.yysemantics.yysval.symbol); ;}
    break;

  case 137:
#line 616 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_constant, yyvsp[0].yystate.yysemantics.yysval.tconstant); ;}
    break;

  case 138:
#line 617 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_constant, yyvsp[0].yystate.yysemantics.yysval.tconstant); ;}
    break;

  case 139:
#line 618 "../standalone/parser.y"
    { (*yyvalp).tcomponent = yyvsp[-1].yystate.yysemantics.yysval.tcomponent; ;}
    break;

  case 140:
#line 619 "../standalone/parser.y"
    { (*yyvalp).tcomponent = yyvsp[-1].yystate.yysemantics.yysval.tcomponent; ;}
    break;

  case 141:
#line 623 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_builtin, b_ref, 2, yyvsp[-3].yystate.yysemantics.yysval.tcomponent, yyvsp[-1].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 142:
#line 627 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_execute, new_clist(parser_memory, yyvsp[-3].yystate.yysemantics.yysval.tcomponent, yyvsp[-1].yystate.yysemantics.yysval.tclist)); ;}
    break;

  case 143:
#line 630 "../standalone/parser.y"
    { (*yyvalp).tclist = NULL; ;}
    break;

  case 144:
#line 631 "../standalone/parser.y"
    { (*yyvalp).tclist = reverse_clist(yyvsp[0].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 145:
#line 634 "../standalone/parser.y"
    { (*yyvalp).tclist = new_clist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tcomponent, yyvsp[-2].yystate.yysemantics.yysval.tclist); ;}
    break;

  case 146:
#line 635 "../standalone/parser.y"
    { (*yyvalp).tclist = new_clist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tcomponent, NULL); ;}
    break;

  case 148:
#line 639 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_quote, yyvsp[-1].yystate.yysemantics.yysval.location, yyvsp[0].yystate.yysemantics.yysval.tconstant); ;}
    break;

  case 149:
#line 640 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_gsymbol, yyvsp[0].yystate.yysemantics.yysval.symbol); ;}
    break;

  case 150:
#line 641 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_table, yyvsp[-1].yystate.yysemantics.yysval.tcstlist); ;}
    break;

  case 151:
#line 642 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_table, NULL); ;}
    break;

  case 152:
#line 643 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_array, yyvsp[-1].yystate.yysemantics.yysval.tcstlist); ;}
    break;

  case 153:
#line 644 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_array, yyvsp[-1].yystate.yysemantics.yysval.tcstlist); ;}
    break;

  case 154:
#line 645 "../standalone/parser.y"
    { 
    (*yyvalp).tconstant = new_constant(parser_memory, cst_list, yyvsp[-3].yystate.yysemantics.yysval.location, new_cstlist(parser_memory, yyvsp[-1].yystate.yysemantics.yysval.tconstant, yyvsp[-2].yystate.yysemantics.yysval.tcstlist));
  ;}
    break;

  case 155:
#line 648 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_list, yyvsp[-1].yystate.yysemantics.yysval.location, NULL); ;}
    break;

  case 156:
#line 651 "../standalone/parser.y"
    { (*yyvalp).tconstant = NULL; ;}
    break;

  case 157:
#line 652 "../standalone/parser.y"
    { (*yyvalp).tconstant = yyvsp[0].yystate.yysemantics.yysval.tconstant; ;}
    break;

  case 159:
#line 656 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_int, yyvsp[0].yystate.yysemantics.yysval.integer); ;}
    break;

  case 160:
#line 657 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_float, yyvsp[0].yystate.yysemantics.yysval.mudlle_float); ;}
    break;

  case 161:
#line 660 "../standalone/parser.y"
    { (*yyvalp).tconstant = new_constant(parser_memory, cst_string, yyvsp[0].yystate.yysemantics.yysval.string); ;}
    break;

  case 162:
#line 663 "../standalone/parser.y"
    { (*yyvalp).tcstlist = NULL; ;}
    break;

  case 164:
#line 667 "../standalone/parser.y"
    { (*yyvalp).tcstlist = new_cstlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tconstant, NULL); ;}
    break;

  case 165:
#line 668 "../standalone/parser.y"
    { (*yyvalp).tcstlist = new_cstlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tconstant, yyvsp[-1].yystate.yysemantics.yysval.tcstlist); ;}
    break;

  case 166:
#line 671 "../standalone/parser.y"
    { (*yyvalp).tcstlist = new_cstlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tconstant, NULL); ;}
    break;

  case 167:
#line 672 "../standalone/parser.y"
    { (*yyvalp).tcstlist = new_cstlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tconstant, yyvsp[-1].yystate.yysemantics.yysval.tcstlist); ;}
    break;

  case 168:
#line 675 "../standalone/parser.y"
    { 
    (*yyvalp).tconstant = new_constant(parser_memory, cst_symbol, 
		      new_cstpair(parser_memory, yyvsp[-2].yystate.yysemantics.yysval.tconstant, yyvsp[0].yystate.yysemantics.yysval.tconstant));
  ;}
    break;

  case 171:
#line 685 "../standalone/parser.y"
    { (*yyvalp).tpattern = new_pattern_expression(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 172:
#line 686 "../standalone/parser.y"
    { (*yyvalp).tpattern = yyvsp[0].yystate.yysemantics.yysval.tpattern; ;}
    break;

  case 174:
#line 690 "../standalone/parser.y"
    { (*yyvalp).tpattern = new_pattern_sink(parser_memory); ;}
    break;

  case 175:
#line 691 "../standalone/parser.y"
    { (*yyvalp).tpattern = new_pattern_symbol(parser_memory, yyvsp[0].yystate.yysemantics.yysval.symbol, stype_any); ;}
    break;

  case 176:
#line 692 "../standalone/parser.y"
    { (*yyvalp).tpattern = new_pattern_constant(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tconstant); ;}
    break;

  case 177:
#line 693 "../standalone/parser.y"
    { (*yyvalp).tpattern = yyvsp[0].yystate.yysemantics.yysval.tpattern; ;}
    break;

  case 178:
#line 696 "../standalone/parser.y"
    { 
    (*yyvalp).tpattern = new_pattern_expression(parser_memory, 
				new_component(parser_memory, c_recall, yyvsp[0].yystate.yysemantics.yysval.symbol));
  ;}
    break;

  case 179:
#line 700 "../standalone/parser.y"
    { (*yyvalp).tpattern = new_pattern_expression(parser_memory, yyvsp[-1].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 180:
#line 703 "../standalone/parser.y"
    { (*yyvalp).tpatternlist = new_pattern_list(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tpattern, NULL); ;}
    break;

  case 181:
#line 704 "../standalone/parser.y"
    { (*yyvalp).tpatternlist = new_pattern_list(parser_memory, yyvsp[0].yystate.yysemantics.yysval.tpattern, yyvsp[-1].yystate.yysemantics.yysval.tpatternlist); ;}
    break;

  case 182:
#line 707 "../standalone/parser.y"
    { (*yyvalp).tpatternlist = NULL; ;}
    break;

  case 184:
#line 711 "../standalone/parser.y"
    { (*yyvalp).tpattern = NULL; ;}
    break;

  case 185:
#line 712 "../standalone/parser.y"
    { (*yyvalp).tpattern = yyvsp[0].yystate.yysemantics.yysval.tpattern; ;}
    break;

  case 186:
#line 715 "../standalone/parser.y"
    { 
    (*yyvalp).tpattern = new_pattern_compound(parser_memory, pat_list, 
			      new_pattern_list(parser_memory, yyvsp[-1].yystate.yysemantics.yysval.tpattern, yyvsp[-2].yystate.yysemantics.yysval.tpatternlist), 0);
  ;}
    break;

  case 187:
#line 719 "../standalone/parser.y"
    { (*yyvalp).tpattern = new_pattern_compound(parser_memory, pat_list, NULL, 0); ;}
    break;

  case 188:
#line 722 "../standalone/parser.y"
    { 
    (*yyvalp).tpattern = new_pattern_compound(parser_memory, pat_array, yyvsp[-2].yystate.yysemantics.yysval.tpatternlist, 1); 
  ;}
    break;

  case 189:
#line 725 "../standalone/parser.y"
    {
    (*yyvalp).tpattern = new_pattern_compound(parser_memory, pat_array, yyvsp[-1].yystate.yysemantics.yysval.tpatternlist, 0);
  ;}
    break;

  case 191:
#line 731 "../standalone/parser.y"
    { (*yyvalp).symbol = "+"; ;}
    break;

  case 194:
#line 740 "../standalone/parser.y"
    { (*yyvalp).tcomponent = new_component(parser_memory, c_block, yyvsp[0].yystate.yysemantics.yysval.tblock); ;}
    break;

  case 195:
#line 744 "../standalone/parser.y"
    { 
    (*yyvalp).tblock = new_codeblock(parser_memory, NULL, yyvsp[-1].yystate.yysemantics.yysval.tclist);
  ;}
    break;

  case 196:
#line 749 "../standalone/parser.y"
    { 
    set_vlist_types(yyvsp[-1].yystate.yysemantics.yysval.tvlist, yyvsp[-2].yystate.yysemantics.yysval.tmtype);
    (*yyvalp).tcomponent = new_component(parser_memory, c_decl, reverse_vlist(yyvsp[-1].yystate.yysemantics.yysval.tvlist));
  ;}
    break;

  case 197:
#line 755 "../standalone/parser.y"
    { 
    (*yyvalp).tvlist = new_vlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.symbol, stype_any, NULL, yyvsp[-2].yystate.yysemantics.yysval.tvlist); ;}
    break;

  case 198:
#line 757 "../standalone/parser.y"
    { 
    (*yyvalp).tvlist = new_vlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.symbol, stype_any, NULL, NULL); ;}
    break;

  case 199:
#line 761 "../standalone/parser.y"
    { lpush(lexloc); ;}
    break;

  case 200:
#line 762 "../standalone/parser.y"
    { (*yyvalp).tcomponent = make_function_decl(yyvsp[-5].yystate.yysemantics.yysval.tmtype, yyvsp[-4].yystate.yysemantics.yysval.symbol, yyvsp[-1].yystate.yysemantics.yysval.string, yyvsp[-2].yystate.yysemantics.yysval.tparameters, yyvsp[0].yystate.yysemantics.yysval.tcomponent); ;}
    break;

  case 203:
#line 769 "../standalone/parser.y"
    { (*yyvalp).tcomponent = yyvsp[-1].yystate.yysemantics.yysval.tcomponent ;}
    break;

  case 205:
#line 773 "../standalone/parser.y"
    { (*yyvalp).tvlist = yyvsp[0].yystate.yysemantics.yysval.tvlist; (*yyvalp).tvlist->next = yyvsp[-2].yystate.yysemantics.yysval.tvlist; ;}
    break;

  case 206:
#line 774 "../standalone/parser.y"
    { (*yyvalp).tvlist = yyvsp[0].yystate.yysemantics.yysval.tvlist ;}
    break;

  case 207:
#line 777 "../standalone/parser.y"
    { (*yyvalp).tvlist = new_vlist(parser_memory, yyvsp[0].yystate.yysemantics.yysval.symbol, stype_any, NULL, NULL); ;}
    break;

  case 208:
#line 778 "../standalone/parser.y"
    { (*yyvalp).tvlist = new_vlist(parser_memory, yyvsp[-2].yystate.yysemantics.yysval.symbol, stype_any, yyvsp[0].yystate.yysemantics.yysval.tcomponent, NULL); ;}
    break;


     }

   return yyok;
# undef yyerrok
# undef YYABORT
# undef YYACCEPT
# undef YYERROR
# undef YYBACKUP
# undef yyclearin
# undef YYRECOVERING
/* Line 671 of glr.c.  */
#line 2462 "parser.tab.c"
}


static YYSTYPE
yyuserMerge (int yyn, YYSTYPE* yy0, YYSTYPE* yy1)
{
  YYSTYPE yyval = *yy0;
  /* `Use' the arguments.  */
  (void) yy0;
  (void) yy1;

  switch (yyn)
    {
      
    }
  return yyval;
}

			      /* Bison grammar-table manipulation.  */

/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (int yytype, YYSTYPE *yyvaluep)
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  switch (yytype)
    {

      default:
        break;
    }
}

/** Number of symbols composing the right hand side of rule #RULE. */
static inline int
yyrhsLength (yyRuleNum yyrule)
{
  return yyr2[yyrule];
}

/** Left-hand-side symbol for rule #RULE. */
static inline yySymbol
yylhsNonterm (yyRuleNum yyrule)
{
  return yyr1[yyrule];
}

#define yyis_pact_ninf(yystate) \
  ((yystate) == YYPACT_NINF)

/** True iff LR state STATE has only a default reduction (regardless
 *  of token). */
static inline bool
yyisDefaultedState (yyStateNum yystate)
{
  return yyis_pact_ninf (yypact[yystate]);
}

/** The default reduction for STATE, assuming it has one. */
static inline yyRuleNum
yydefaultAction (yyStateNum yystate)
{
  return yydefact[yystate];
}

#define yyis_table_ninf(yytable_value) \
  0

/** Set *YYACTION to the action to take in YYSTATE on seeing YYTOKEN.
 *  Result R means
 *    R < 0:  Reduce on rule -R.
 *    R = 0:  Error.
 *    R > 0:  Shift to state R.
 *  Set *CONFLICTS to a pointer into yyconfl to 0-terminated list of
 *  conflicting reductions.
 */
static inline void
yygetLRActions (yyStateNum yystate, int yytoken,
	        int* yyaction, const short** yyconflicts)
{
  int yyindex = yypact[yystate] + yytoken;
  if (yyindex < 0 || YYLAST < yyindex || yycheck[yyindex] != yytoken)
    {
      *yyaction = -yydefact[yystate];
      *yyconflicts = yyconfl;
    }
  else if (! yyis_table_ninf (yytable[yyindex]))
    {
      *yyaction = yytable[yyindex];
      *yyconflicts = yyconfl + yyconflp[yyindex];
    }
  else
    {
      *yyaction = 0;
      *yyconflicts = yyconfl + yyconflp[yyindex];
    }
}

static inline yyStateNum
yyLRgotoState (yyStateNum yystate, yySymbol yylhs)
{
  int yyr;
  yyr = yypgoto[yylhs - YYNTOKENS] + yystate;
  if (0 <= yyr && yyr <= YYLAST && yycheck[yyr] == yystate)
    return yytable[yyr];
  else
    return yydefgoto[yylhs - YYNTOKENS];
}

static inline bool
yyisShiftAction (int yyaction)
{
  return 0 < yyaction;
}

static inline bool
yyisErrorAction (int yyaction)
{
  return yyaction == 0;
}

				/* GLRStates */

static void
yyaddDeferredAction (yyGLRStack* yystack, yyGLRState* yystate,
		     yyGLRState* rhs, yyRuleNum yyrule)
{
  yySemanticOption* yynewItem;
  yynewItem = &yystack->yynextFree->yyoption;
  yystack->yyspaceLeft -= 1;
  yystack->yynextFree += 1;
  yynewItem->yyisState = yyfalse;
  yynewItem->yystate = rhs;
  yynewItem->yyrule = yyrule;
  yynewItem->yynext = yystate->yysemantics.yyfirstVal;
  yystate->yysemantics.yyfirstVal = yynewItem;
  if (yystack->yyspaceLeft < YYHEADROOM)
    yyexpandGLRStack (yystack);
}

				/* GLRStacks */

/** Initialize SET to a singleton set containing an empty stack. */
static void
yyinitStateSet (yyGLRStateSet* yyset)
{
  yyset->yysize = 1;
  yyset->yycapacity = 16;
  yyset->yystates = (yyGLRState**) malloc (16 * sizeof (yyset->yystates[0]));
  yyset->yystates[0] = NULL;
}

static void yyfreeStateSet (yyGLRStateSet* yyset)
{
  free (yyset->yystates);
}

/** Initialize STACK to a single empty stack, with total maximum
 *  capacity for all stacks of SIZE. */
static void
yyinitGLRStack (yyGLRStack* yystack, size_t yysize)
{
  yystack->yyerrflag = 0;
  yystack->yyerrState = 0;
  yynerrs = 0;
  yystack->yyspaceLeft = yysize;
  yystack->yynextFree = yystack->yyitems =
    (yyGLRStackItem*) malloc (yysize * sizeof (yystack->yynextFree[0]));
  yystack->yysplitPoint = NULL;
  yystack->yylastDeleted = NULL;
  yyinitStateSet (&yystack->yytops);
}

#define YYRELOC(YYFROMITEMS,YYTOITEMS,YYX,YYTYPE) \
  &((YYTOITEMS) - ((YYFROMITEMS) - (yyGLRStackItem*) (YYX)))->YYTYPE

/** If STACK is expandable, extend it.  WARNING: Pointers into the
    stack from outside should be considered invalid after this call.
    We always expand when there are 1 or fewer items left AFTER an
    allocation, so that we can avoid having external pointers exist
    across an allocation. */
static void
yyexpandGLRStack (yyGLRStack* yystack)
{
#if YYSTACKEXPANDABLE
  yyGLRStack yynewStack;
  yyGLRStackItem* yyp0, *yyp1;
  size_t yysize, yynewSize;
  size_t yyn;
  yysize = yystack->yynextFree - yystack->yyitems;
  if (YYMAXDEPTH <= yysize)
    yyFail (yystack, "parser stack overflow");
  yynewSize = 2*yysize;
  if (YYMAXDEPTH < yynewSize)
    yynewSize = YYMAXDEPTH;
  yyinitGLRStack (&yynewStack, yynewSize);
  for (yyp0 = yystack->yyitems, yyp1 = yynewStack.yyitems, yyn = yysize;
       0 < yyn;
       yyn -= 1, yyp0 += 1, yyp1 += 1)
    {
      *yyp1 = *yyp0;
      if (*(bool*) yyp0)
	{
	  yyGLRState* yys0 = &yyp0->yystate;
	  yyGLRState* yys1 = &yyp1->yystate;
	  if (yys0->yypred != NULL)
	    yys1->yypred =
	      YYRELOC (yyp0, yyp1, yys0->yypred, yystate);
	  if (! yys0->yyresolved && yys0->yysemantics.yyfirstVal != NULL)
	    yys1->yysemantics.yyfirstVal =
	      YYRELOC(yyp0, yyp1, yys0->yysemantics.yyfirstVal, yyoption);
	}
      else
	{
	  yySemanticOption* yyv0 = &yyp0->yyoption;
	  yySemanticOption* yyv1 = &yyp1->yyoption;
	  if (yyv0->yystate != NULL)
	    yyv1->yystate = YYRELOC (yyp0, yyp1, yyv0->yystate, yystate);
	  if (yyv0->yynext != NULL)
	    yyv1->yynext = YYRELOC (yyp0, yyp1, yyv0->yynext, yyoption);
	}
    }
  if (yystack->yysplitPoint != NULL)
    yystack->yysplitPoint = YYRELOC (yystack->yyitems, yynewStack.yyitems,
				 yystack->yysplitPoint, yystate);

  for (yyn = 0; yyn < yystack->yytops.yysize; yyn += 1)
    if (yystack->yytops.yystates[yyn] != NULL)
      yystack->yytops.yystates[yyn] =
	YYRELOC (yystack->yyitems, yynewStack.yyitems,
		 yystack->yytops.yystates[yyn], yystate);
  free (yystack->yyitems);
  yystack->yyitems = yynewStack.yyitems;
  yystack->yynextFree = yynewStack.yynextFree + yysize;
  yystack->yyspaceLeft = yynewStack.yyspaceLeft - yysize;

#else

  yyFail (yystack, "parser stack overflow");
#endif
}

static void
yyfreeGLRStack (yyGLRStack* yystack)
{
  free (yystack->yyitems);
  yyfreeStateSet (&yystack->yytops);
}

/** Assuming that S is a GLRState somewhere on STACK, update the
 *  splitpoint of STACK, if needed, so that it is at least as deep as
 *  S. */
static inline void
yyupdateSplit (yyGLRStack* yystack, yyGLRState* yys)
{
  if (yystack->yysplitPoint != NULL && yystack->yysplitPoint > yys)
    yystack->yysplitPoint = yys;
}

/** Invalidate stack #K in STACK. */
static inline void
yymarkStackDeleted (yyGLRStack* yystack, int yyk)
{
  if (yystack->yytops.yystates[yyk] != NULL)
    yystack->yylastDeleted = yystack->yytops.yystates[yyk];
  yystack->yytops.yystates[yyk] = NULL;
}

/** Undelete the last stack that was marked as deleted.  Can only be
    done once after a deletion, and only when all other stacks have
    been deleted. */
static void
yyundeleteLastStack (yyGLRStack* yystack)
{
  if (yystack->yylastDeleted == NULL || yystack->yytops.yysize != 0)
    return;
  yystack->yytops.yystates[0] = yystack->yylastDeleted;
  yystack->yytops.yysize = 1;
  YYDPRINTF ((stderr, "Restoring last deleted stack as stack #0.\n"));
  yystack->yylastDeleted = NULL;
}

static inline void
yyremoveDeletes (yyGLRStack* yystack)
{
  size_t yyi, yyj;
  yyi = yyj = 0;
  while (yyj < yystack->yytops.yysize)
    {
      if (yystack->yytops.yystates[yyi] == NULL)
	{
	  if (yyi == yyj)
	    {
	      YYDPRINTF ((stderr, "Removing dead stacks.\n"));
	    }
	  yystack->yytops.yysize -= 1;
	}
      else
	{
	  yystack->yytops.yystates[yyj] = yystack->yytops.yystates[yyi];
	  if (yyj != yyi)
	    {
	      YYDPRINTF ((stderr, "Rename stack %d -> %d.\n", yyi, yyj));
	    }
	  yyj += 1;
	}
      yyi += 1;
    }
}

/** Shift to a new state on stack #K of STACK, corresponding to LR state
 * LRSTATE, at input position POSN, with (resolved) semantic value SVAL. */
static inline void
yyglrShift (yyGLRStack* yystack, int yyk, yyStateNum yylrState, size_t yyposn,
	    YYSTYPE yysval, YYLTYPE* yylocp)
{
  yyGLRStackItem* yynewItem;

  yynewItem = yystack->yynextFree;
  yystack->yynextFree += 1;
  yystack->yyspaceLeft -= 1;
  yynewItem->yystate.yyisState = yytrue;
  yynewItem->yystate.yylrState = yylrState;
  yynewItem->yystate.yyposn = yyposn;
  yynewItem->yystate.yyresolved = yytrue;
  yynewItem->yystate.yypred = yystack->yytops.yystates[yyk];
  yystack->yytops.yystates[yyk] = &yynewItem->yystate;
  yynewItem->yystate.yysemantics.yysval = yysval;
  yynewItem->yystate.yyloc = *yylocp;
  if (yystack->yyspaceLeft < YYHEADROOM)
    yyexpandGLRStack (yystack);
}

/** Shift to a new state on stack #K of STACK, to a new state
 *  corresponding to LR state LRSTATE, at input position POSN, with
 * the (unresolved) semantic value of RHS under the action for RULE. */
static inline void
yyglrShiftDefer (yyGLRStack* yystack, int yyk, yyStateNum yylrState,
		 size_t yyposn, yyGLRState* rhs, yyRuleNum yyrule)
{
  yyGLRStackItem* yynewItem;

  yynewItem = yystack->yynextFree;
  yynewItem->yystate.yyisState = yytrue;
  yynewItem->yystate.yylrState = yylrState;
  yynewItem->yystate.yyposn = yyposn;
  yynewItem->yystate.yyresolved = yyfalse;
  yynewItem->yystate.yypred = yystack->yytops.yystates[yyk];
  yynewItem->yystate.yysemantics.yyfirstVal = NULL;
  yystack->yytops.yystates[yyk] = &yynewItem->yystate;
  yystack->yynextFree += 1;
  yystack->yyspaceLeft -= 1;
  yyaddDeferredAction (yystack, &yynewItem->yystate, rhs, yyrule);
}

/** Pop the symbols consumed by reduction #RULE from the top of stack
 *  #K of STACK, and perform the appropriate semantic action on their
 *  semantic values.  Assumes that all ambiguities in semantic values
 *  have been previously resolved. Set *VALP to the resulting value,
 *  and *LOCP to the computed location (if any).  Return value is as
 *  for userAction. */
static inline YYRESULTTAG
yydoAction (yyGLRStack* yystack, int yyk, yyRuleNum yyrule,
 	    YYSTYPE* yyvalp, YYLTYPE* yylocp)
{
  int yynrhs = yyrhsLength (yyrule);

  if (yystack->yysplitPoint == NULL)
    {
      /* Standard special case: single stack. */
      yyGLRStackItem* rhs = (yyGLRStackItem*) yystack->yytops.yystates[yyk];
      if (yyk != 0)
	abort ();
      yystack->yynextFree -= yynrhs;
      yystack->yyspaceLeft += yynrhs;
      yystack->yytops.yystates[0] = & yystack->yynextFree[-1].yystate;
      if (yynrhs == 0)
	{
	  *yyvalp = yyval_default;
	  *yylocp = yyloc_default;
	}
      else
	{
	  *yyvalp = rhs[1-yynrhs].yystate.yysemantics.yysval;
	  *yylocp = rhs[1-yynrhs].yystate.yyloc;
	}
      return yyuserAction (yyrule, yynrhs, rhs,
			   yyvalp, yylocp, yystack);
    }
  else
    {
      int yyi;
      yyGLRState* yys;
      yyGLRStackItem yyrhsVals[YYMAXRHS];
      for (yyi = yynrhs-1, yys = yystack->yytops.yystates[yyk]; 0 <= yyi;
	   yyi -= 1, yys = yys->yypred)
	{
	  if (! yys->yypred)
	    abort ();
	  yyrhsVals[yyi].yystate.yyresolved = yytrue;
	  yyrhsVals[yyi].yystate.yysemantics.yysval = yys->yysemantics.yysval;
	  yyrhsVals[yyi].yystate.yyloc = yys->yyloc;
	}
      yyupdateSplit (yystack, yys);
      yystack->yytops.yystates[yyk] = yys;
      if (yynrhs == 0)
	{
	  *yyvalp = yyval_default;
	  *yylocp = yyloc_default;
	}
      else
	{
	  *yyvalp = yyrhsVals[0].yystate.yysemantics.yysval;
	  *yylocp = yyrhsVals[0].yystate.yyloc;
	}
      return yyuserAction (yyrule, yynrhs, yyrhsVals + (yynrhs-1),
			   yyvalp, yylocp, yystack);
    }
}

#if !YYDEBUG
# define YY_REDUCE_PRINT(K, Rule)
#else
# define YY_REDUCE_PRINT(K, Rule)	\
do {					\
  if (yydebug)				\
    yy_reduce_print (K, Rule);		\
} while (0)

/*----------------------------------------------------------.
| Report that the RULE is going to be reduced on stack #K.  |
`----------------------------------------------------------*/

static inline void
yy_reduce_print (size_t yyk, yyRuleNum yyrule)
{
  int yyi;
  unsigned int yylineno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack %d by rule %d (line %u), ",
	     yyk, yyrule - 1, yylineno);
  /* Print the symbols being reduced, and their result.  */
  for (yyi = yyprhs[yyrule]; 0 <= yyrhs[yyi]; yyi++)
    YYFPRINTF (stderr, "%s ", yytokenName (yyrhs[yyi]));
  YYFPRINTF (stderr, "-> %s\n", yytokenName (yyr1[yyrule]));
}
#endif

/** Pop items off stack #K of STACK according to grammar rule RULE,
 *  and push back on the resulting nonterminal symbol.  Perform the
 *  semantic action associated with RULE and store its value with the
 *  newly pushed state, if FORCEEVAL or if STACK is currently
 *  unambiguous.  Otherwise, store the deferred semantic action with
 *  the new state.  If the new state would have an identical input
 *  position, LR state, and predecessor to an existing state on the stack,
 *  it is identified with that existing state, eliminating stack #K from
 *  the STACK. In this case, the (necessarily deferred) semantic value is
 *  added to the options for the existing state's semantic value.
 */
static inline YYRESULTTAG
yyglrReduce (yyGLRStack* yystack, size_t yyk, yyRuleNum yyrule,
             bool yyforceEval)
{
  size_t yyposn = yystack->yytops.yystates[yyk]->yyposn;

  if (yyforceEval || yystack->yysplitPoint == NULL)
    {
      YYSTYPE yysval;
      YYLTYPE yyloc;

      YY_REDUCE_PRINT (yyk, yyrule);
      YYCHK (yydoAction (yystack, yyk, yyrule, &yysval, &yyloc));
      yyglrShift (yystack, yyk,
		  yyLRgotoState (yystack->yytops.yystates[yyk]->yylrState,
				 yylhsNonterm (yyrule)),
		  yyposn, yysval, &yyloc);
    }
  else
    {
      size_t yyi;
      int yyn;
      yyGLRState* yys, *yys0 = yystack->yytops.yystates[yyk];
      yyStateNum yynewLRState;

      for (yys = yystack->yytops.yystates[yyk], yyn = yyrhsLength (yyrule);
	   0 < yyn; yyn -= 1)
	{
	  yys = yys->yypred;
	  if (! yys)
	    abort ();
	}
      yyupdateSplit (yystack, yys);
      yynewLRState = yyLRgotoState (yys->yylrState, yylhsNonterm (yyrule));
      YYDPRINTF ((stderr,
		  "Reduced stack %d by rule #%d; action deferred. "
		  "Now in state %d.\n",
		  yyk, yyrule-1, yynewLRState));
      for (yyi = 0; yyi < yystack->yytops.yysize; yyi += 1)
	if (yyi != yyk && yystack->yytops.yystates[yyi] != NULL)
	  {
	    yyGLRState* yyp, *yysplit = yystack->yysplitPoint;
	    yyp = yystack->yytops.yystates[yyi];
	    while (yyp != yys && yyp != yysplit && yyp->yyposn >= yyposn)
	      {
		if (yyp->yylrState == yynewLRState && yyp->yypred == yys)
		  {
		    yyaddDeferredAction (yystack, yyp, yys0, yyrule);
		    yymarkStackDeleted (yystack, yyk);
		    YYDPRINTF ((stderr, "Merging stack %d into stack %d.\n",
				yyk, yyi));
		    return yyok;
		  }
		yyp = yyp->yypred;
	      }
	  }
      yystack->yytops.yystates[yyk] = yys;
      yyglrShiftDefer (yystack, yyk, yynewLRState, yyposn, yys0, yyrule);
    }
  return yyok;
}

static int
yysplitStack (yyGLRStack* yystack, int yyk)
{
  if (yystack->yysplitPoint == NULL)
    {
      if (yyk != 0)
	abort ();
      yystack->yysplitPoint = yystack->yytops.yystates[yyk];
    }
  if (yystack->yytops.yysize >= yystack->yytops.yycapacity)
    {
      yystack->yytops.yycapacity *= 2;
      yystack->yytops.yystates =
	(yyGLRState**) realloc (yystack->yytops.yystates,
				yystack->yytops.yycapacity
				* sizeof (yyGLRState*));
    }
  yystack->yytops.yystates[yystack->yytops.yysize]
    = yystack->yytops.yystates[yyk];
  yystack->yytops.yysize += 1;
  return yystack->yytops.yysize-1;
}

/** True iff Y0 and Y1 represent identical options at the top level.
 *  That is, they represent the same rule applied to RHS symbols
 *  that produce the same terminal symbols. */
static bool
yyidenticalOptions (yySemanticOption* yyy0, yySemanticOption* yyy1)
{
  if (yyy0->yyrule == yyy1->yyrule)
    {
      yyGLRState *yys0, *yys1;
      int yyn;
      for (yys0 = yyy0->yystate, yys1 = yyy1->yystate,
	   yyn = yyrhsLength (yyy0->yyrule);
	   yyn > 0;
	   yys0 = yys0->yypred, yys1 = yys1->yypred, yyn -= 1)
	if (yys0->yyposn != yys1->yyposn)
	  return yyfalse;
      return yytrue;
    }
  else
    return yyfalse;
}

/** Assuming identicalOptions (Y0,Y1), (destructively) merge the
 *  alternative semantic values for the RHS-symbols of Y1 into the
 *  corresponding semantic value sets of the symbols of Y0. */
static void
yymergeOptionSets (yySemanticOption* yyy0, yySemanticOption* yyy1)
{
  yyGLRState *yys0, *yys1;
  int yyn;
  for (yys0 = yyy0->yystate, yys1 = yyy1->yystate,
       yyn = yyrhsLength (yyy0->yyrule);
       yyn > 0;
       yys0 = yys0->yypred, yys1 = yys1->yypred, yyn -= 1)
    if (yys0 == yys1)
      break;
    else if (! yys0->yyresolved && ! yys1->yyresolved)
      {
	yySemanticOption* yyz;
	for (yyz = yys0->yysemantics.yyfirstVal; yyz->yynext != NULL;
	     yyz = yyz->yynext)
	  continue;
	yyz->yynext = yys1->yysemantics.yyfirstVal;
      }
}

/** Y0 and Y1 represent two possible actions to take in a given
 *  parsing state; return 0 if no combination is possible,
 *  1 if user-mergeable, 2 if Y0 is preferred, 3 if Y1 is preferred. */
static int
yypreference (yySemanticOption* y0, yySemanticOption* y1)
{
  yyRuleNum r0 = y0->yyrule, r1 = y1->yyrule;
  int p0 = yydprec[r0], p1 = yydprec[r1];

  if (p0 == p1)
    {
      if (yymerger[r0] == 0 || yymerger[r0] != yymerger[r1])
	return 0;
      else
	return 1;
    }
  if (p0 == 0 || p1 == 0)
    return 0;
  if (p0 < p1)
    return 3;
  if (p1 < p0)
    return 2;
  return 0;
}

static YYRESULTTAG yyresolveValue (yySemanticOption* yyoptionList,
				   yyGLRStack* yystack, YYSTYPE* yyvalp,
				   YYLTYPE* yylocp);

static YYRESULTTAG
yyresolveStates (yyGLRState* yys, int yyn, yyGLRStack* yystack)
{
  YYRESULTTAG yyflag;
  if (0 < yyn)
    {
      if (! yys->yypred)
	abort ();
      yyflag = yyresolveStates (yys->yypred, yyn-1, yystack);
      if (yyflag != yyok)
	return yyflag;
      if (! yys->yyresolved)
	{
	  yyflag = yyresolveValue (yys->yysemantics.yyfirstVal, yystack,
				   &yys->yysemantics.yysval, &yys->yyloc
				  );
	  if (yyflag != yyok)
	    return yyflag;
	  yys->yyresolved = yytrue;
	}
    }
  return yyok;
}

static YYRESULTTAG
yyresolveAction (yySemanticOption* yyopt, yyGLRStack* yystack,
	         YYSTYPE* yyvalp, YYLTYPE* yylocp)
{
  yyGLRStackItem yyrhsVals[YYMAXRHS];
  int yynrhs, yyi;
  yyGLRState* yys;

  yynrhs = yyrhsLength (yyopt->yyrule);
  YYCHK (yyresolveStates (yyopt->yystate, yynrhs, yystack));
  for (yyi = yynrhs-1, yys = yyopt->yystate; 0 <= yyi;
       yyi -= 1, yys = yys->yypred)
    {
      if (! yys->yypred)
	abort ();
      yyrhsVals[yyi].yystate.yyresolved = yytrue;
      yyrhsVals[yyi].yystate.yysemantics.yysval = yys->yysemantics.yysval;
      yyrhsVals[yyi].yystate.yyloc = yys->yyloc;
    }
  return yyuserAction (yyopt->yyrule, yynrhs, yyrhsVals + (yynrhs-1),
		       yyvalp, yylocp, yystack);
}

#if YYDEBUG
static void
yyreportTree (yySemanticOption* yyx, int yyindent)
{
  int yynrhs = yyrhsLength (yyx->yyrule);
  int yyi;
  yyGLRState* yys;
  yyGLRState* yystates[YYMAXRHS];
  yyGLRState yyleftmost_state;

  for (yyi = yynrhs, yys = yyx->yystate; 0 < yyi; yyi -= 1, yys = yys->yypred)
    yystates[yyi] = yys;
  if (yys == NULL)
    {
      yyleftmost_state.yyposn = 0;
      yystates[0] = &yyleftmost_state;
    }
  else
    yystates[0] = yys;

  if (yyx->yystate->yyposn < yys->yyposn + 1)
    YYFPRINTF (stderr, "%*s%s -> <Rule %d, empty>\n",
	       yyindent, "", yytokenName (yylhsNonterm (yyx->yyrule)),
	       yyx->yyrule);
  else
    YYFPRINTF (stderr, "%*s%s -> <Rule %d, tokens %d .. %d>\n",
	       yyindent, "", yytokenName (yylhsNonterm (yyx->yyrule)),
	       yyx->yyrule, yys->yyposn+1, yyx->yystate->yyposn);
  for (yyi = 1; yyi <= yynrhs; yyi += 1)
    {
      if (yystates[yyi]->yyresolved)
	{
	  if (yystates[yyi-1]->yyposn+1 > yystates[yyi]->yyposn)
	    YYFPRINTF (stderr, "%*s%s <empty>\n", yyindent+2, "",
		       yytokenName (yyrhs[yyprhs[yyx->yyrule]+yyi-1]));
	  else
	    YYFPRINTF (stderr, "%*s%s <tokens %d .. %d>\n", yyindent+2, "",
		       yytokenName (yyrhs[yyprhs[yyx->yyrule]+yyi-1]),
		       yystates[yyi-1]->yyposn+1, yystates[yyi]->yyposn);
	}
      else
	yyreportTree (yystates[yyi]->yysemantics.yyfirstVal, yyindent+2);
    }
}
#endif

static void
yyreportAmbiguity (yySemanticOption* yyx0, yySemanticOption* yyx1,
		   yyGLRStack* yystack)
{
  /* `Unused' warnings.  */
  (void) yyx0;
  (void) yyx1;

#if YYDEBUG
  YYFPRINTF (stderr, "Ambiguity detected.\n");
  YYFPRINTF (stderr, "Option 1,\n");
  yyreportTree (yyx0, 2);
  YYFPRINTF (stderr, "\nOption 2,\n");
  yyreportTree (yyx1, 2);
  YYFPRINTF (stderr, "\n");
#endif
  yyFail (yystack, "ambiguity detected");
}


/** Resolve the ambiguity represented by OPTIONLIST, perform the indicated
 *  actions, and return the result. */
static YYRESULTTAG
yyresolveValue (yySemanticOption* yyoptionList, yyGLRStack* yystack,
		YYSTYPE* yyvalp, YYLTYPE* yylocp)
{
  yySemanticOption* yybest;
  yySemanticOption* yyp;
  int yymerge;

  yybest = yyoptionList;
  yymerge = 0;
  for (yyp = yyoptionList->yynext; yyp != NULL; yyp = yyp->yynext)
    {
      if (yyidenticalOptions (yybest, yyp))
	yymergeOptionSets (yybest, yyp);
      else
	switch (yypreference (yybest, yyp))
	  {
	  case 0:
	    yyreportAmbiguity (yybest, yyp, yystack);
	    break;
	  case 1:
	    yymerge = 1;
	    break;
	  case 2:
	    break;
	  case 3:
	    yybest = yyp;
	    yymerge = 0;
	    break;
	  }
    }

  if (yymerge)
    {
      int yyprec = yydprec[yybest->yyrule];
      YYCHK (yyresolveAction (yybest, yystack, yyvalp, yylocp));
      for (yyp = yybest->yynext; yyp != NULL; yyp = yyp->yynext)
	{
	  if (yyprec == yydprec[yyp->yyrule])
	    {
	      YYSTYPE yyval1;
	      YYLTYPE yydummy;
	      YYCHK (yyresolveAction (yyp, yystack, &yyval1, &yydummy));
	      *yyvalp = yyuserMerge (yymerger[yyp->yyrule], yyvalp, &yyval1);
	    }
	}
      return yyok;
    }
  else
    return yyresolveAction (yybest, yystack, yyvalp, yylocp);
}

static YYRESULTTAG
yyresolveStack (yyGLRStack* yystack)
{
  if (yystack->yysplitPoint != NULL)
    {
      yyGLRState* yys;
      int yyn;

      for (yyn = 0, yys = yystack->yytops.yystates[0];
	   yys != yystack->yysplitPoint;
	   yys = yys->yypred, yyn += 1)
	continue;
      YYCHK (yyresolveStates (yystack->yytops.yystates[0], yyn, yystack
			     ));
    }
  return yyok;
}

static void
yycompressStack (yyGLRStack* yystack)
{
  yyGLRState* yyp, *yyq, *yyr;

  if (yystack->yytops.yysize != 1 || yystack->yysplitPoint == NULL)
    return;

  for (yyp = yystack->yytops.yystates[0], yyq = yyp->yypred, yyr = NULL;
       yyp != yystack->yysplitPoint;
       yyr = yyp, yyp = yyq, yyq = yyp->yypred)
    yyp->yypred = yyr;

  yystack->yyspaceLeft += yystack->yynextFree - yystack->yyitems;
  yystack->yynextFree = ((yyGLRStackItem*) yystack->yysplitPoint) + 1;
  yystack->yyspaceLeft -= yystack->yynextFree - yystack->yyitems;
  yystack->yysplitPoint = NULL;
  yystack->yylastDeleted = NULL;

  while (yyr != NULL)
    {
      yystack->yynextFree->yystate = *yyr;
      yyr = yyr->yypred;
      yystack->yynextFree->yystate.yypred = & yystack->yynextFree[-1].yystate;
      yystack->yytops.yystates[0] = &yystack->yynextFree->yystate;
      yystack->yynextFree += 1;
      yystack->yyspaceLeft -= 1;
    }
}

static YYRESULTTAG
yyprocessOneStack (yyGLRStack* yystack, int yyk,
	           size_t yyposn, YYSTYPE* yylvalp, YYLTYPE* yyllocp
		  )
{
  int yyaction;
  const short* yyconflicts;
  yyRuleNum yyrule;
  yySymbol* const yytokenp = yystack->yytokenp;

  while (yystack->yytops.yystates[yyk] != NULL)
    {
      yyStateNum yystate = yystack->yytops.yystates[yyk]->yylrState;
      YYDPRINTF ((stderr, "Stack %d Entering state %d\n", yyk, yystate));

      if (yystate == YYFINAL)
	abort ();
      if (yyisDefaultedState (yystate))
	{
	  yyrule = yydefaultAction (yystate);
	  if (yyrule == 0)
	    {
	      YYDPRINTF ((stderr, "Stack %d dies.\n", yyk));
	      yymarkStackDeleted (yystack, yyk);
	      return yyok;
	    }
	  YYCHK (yyglrReduce (yystack, yyk, yyrule, yyfalse));
	}
      else
	{
	  if (*yytokenp == YYEMPTY)
	    {
	      YYDPRINTF ((stderr, "Reading a token: "));
	      yychar = YYLEX;
	      *yytokenp = YYTRANSLATE (yychar);
	      YYDSYMPRINTF ("Next token is", *yytokenp, yylvalp, yyllocp);
	    }
	  yygetLRActions (yystate, *yytokenp, &yyaction, &yyconflicts);

	  while (*yyconflicts != 0)
	    {
	      int yynewStack = yysplitStack (yystack, yyk);
	      YYDPRINTF ((stderr, "Splitting off stack %d from %d.\n",
			  yynewStack, yyk));
	      YYCHK (yyglrReduce (yystack, yynewStack,
				  *yyconflicts, yyfalse));
	      YYCHK (yyprocessOneStack (yystack, yynewStack, yyposn,
					yylvalp, yyllocp));
	      yyconflicts += 1;
	    }

	  if (yyisShiftAction (yyaction))
	    {
	      YYDPRINTF ((stderr, "Shifting token %s on stack %d, ",
			  yytokenName (*yytokenp), yyk));
	      yyglrShift (yystack, yyk, yyaction, yyposn+1,
			  *yylvalp, yyllocp);
	      YYDPRINTF ((stderr, "which is now in state #%d\n",
			  yystack->yytops.yystates[yyk]->yylrState));
	      break;
	    }
	  else if (yyisErrorAction (yyaction))
	    {
	      YYDPRINTF ((stderr, "Stack %d dies.\n", yyk));
	      yymarkStackDeleted (yystack, yyk);
	      break;
	    }
	  else
	    YYCHK (yyglrReduce (yystack, yyk, -yyaction, yyfalse));
	}
    }
  return yyok;
}

static void
yyreportSyntaxError (yyGLRStack* yystack,
		     YYSTYPE* yylvalp, YYLTYPE* yyllocp)
{
  /* `Unused' warnings. */
  (void) yylvalp;
  (void) yyllocp;

  if (yystack->yyerrState == 0)
    {
#if YYERROR_VERBOSE
      yySymbol* const yytokenp = yystack->yytokenp;
      int yyn, yyx, yycount;
      size_t yysize;
      const char* yyprefix;
      char* yyp;
      char* yymsg;
      yyn = yypact[yystack->yytops.yystates[0]->yylrState];
      if (YYPACT_NINF < yyn && yyn < YYLAST)
	{
	  yycount = 0;
	  /* Start YYX at -YYN if negative to avoid negative indexes in
	     YYCHECK.  */
	  yysize = sizeof ("syntax error, unexpected ")
	    + strlen (yytokenName (*yytokenp));
	  yyprefix = ", expecting ";
	  for (yyx = yyn < 0 ? -yyn : 0; yyx < yytname_size && yycount <= 5;
	       yyx += 1)
	    if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	      yysize += strlen (yytokenName (yyx)) + strlen (yyprefix),
		yycount += 1, yyprefix = " or ";
	  yymsg = yyp = (char*) malloc (yysize);
	  sprintf (yyp, "syntax error, unexpected %s",
		   yytokenName (*yytokenp));
	  yyp += strlen (yyp);
	  if (yycount < 5)
	    {
	      yyprefix = ", expecting ";
	      for (yyx = yyn < 0 ? -yyn : 0; yyx < yytname_size; yyx += 1)
		if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
		  {
		    sprintf (yyp, "%s%s", yyprefix, yytokenName (yyx));
		    yyp += strlen (yyp);
		    yyprefix = " or ";
		  }
	    }
	  yyerror (yymsg);
	  free (yymsg);
	}
      else
#endif
	yyerror ("syntax error");
      yynerrs += 1;
    }
}

/* Recover from a syntax error on YYSTACK, assuming that YYTOKENP,
   YYLVALP, and YYLLOCP point to the syntactic category, semantic
   value, and location of the lookahead.  */
static void
yyrecoverSyntaxError (yyGLRStack* yystack,
		      YYSTYPE* yylvalp, YYLTYPE* yyllocp)
{
  yySymbol* const yytokenp = yystack->yytokenp;
  size_t yyk;
  int yyj;

  if (yystack->yyerrState == 0)
    yystack->yyerrState = 3;
  else if (yystack->yyerrState == 3)
    /* We just shifted the error token and (perhaps) took some
       reductions.  Skip tokens until we can proceed.  */
    while (yytrue)
      {
	if (*yytokenp == YYEOF)
	  {
	    /* Now pop stack until we find a state that shifts the
	       error token.  */
	    while (yystack->yytops.yystates[0] != NULL)
	      {
		yyGLRState *yys = yystack->yytops.yystates[0];
		YYDSYMPRINTF ("Error: popping",
			      yystos[yys->yylrState],
			      &yys->yysemantics.yysval, &yys->yyloc);
		yydestruct (yystos[yys->yylrState],
			    &yys->yysemantics.yysval);
		yystack->yytops.yystates[0] = yys->yypred;
		yystack->yynextFree -= 1;
		yystack->yyspaceLeft += 1;
	      }
	    yyFail (yystack, NULL);
	  }
	if (*yytokenp != YYEMPTY)
	  {
	    YYDSYMPRINTF ("Error: discarding", *yytokenp, yylvalp, yyllocp);
	    yydestruct (*yytokenp, yylvalp);
	  }
	YYDPRINTF ((stderr, "Reading a token: "));
	yychar = YYLEX;
	*yytokenp = YYTRANSLATE (yychar);
	YYDSYMPRINTF ("Next token is", *yytokenp, yylvalp, yyllocp);
	yyj = yypact[yystack->yytops.yystates[0]->yylrState];
	if (yyis_pact_ninf (yyj))
	  /* Something's not right; we shouldn't be here.  */
	  yyFail (yystack, NULL);
	yyj += *yytokenp;
	if (yyj < 0 || YYLAST < yyj || yycheck[yyj] != *yytokenp)
	  {
	    if (yydefact[yystack->yytops.yystates[0]->yylrState] != 0)
	      return;
	  }
	else if (yytable[yyj] != 0 && ! yyis_table_ninf (yytable[yyj]))
	  return;
      }

  /* Reduce to one stack.  */
  for (yyk = 0; yyk < yystack->yytops.yysize; yyk += 1)
    if (yystack->yytops.yystates[yyk] != NULL)
      break;
  if (yyk >= yystack->yytops.yysize)
    yyFail (yystack, NULL);
  for (yyk += 1; yyk < yystack->yytops.yysize; yyk += 1)
    yymarkStackDeleted (yystack, yyk);
  yyremoveDeletes (yystack);
  yycompressStack (yystack);

  /* Now pop stack until we find a state that shifts the error token. */
  while (yystack->yytops.yystates[0] != NULL)
    {
      yyGLRState *yys = yystack->yytops.yystates[0];
      yyj = yypact[yys->yylrState];
      if (! yyis_pact_ninf (yyj))
	{
	  yyj += YYTERROR;
	  if (0 <= yyj && yyj <= YYLAST && yycheck[yyj] == YYTERROR
	      && yyisShiftAction (yytable[yyj]))
	    {
	      YYDPRINTF ((stderr, "Shifting error token, "));
	      yyglrShift (yystack, 0, yytable[yyj],
			  yys->yyposn, *yylvalp, yyllocp);
	      break;
	    }
	}
      YYDSYMPRINTF ("Error: popping",
 		    yystos[yys->yylrState],
 		    &yys->yysemantics.yysval, &yys->yyloc);
      yydestruct (yystos[yys->yylrState],
 	          &yys->yysemantics.yysval);
      yystack->yytops.yystates[0] = yys->yypred;
      yystack->yynextFree -= 1;
      yystack->yyspaceLeft += 1;
    }
  if (yystack->yytops.yystates[0] == NULL)
    yyFail (yystack, NULL);
}

#define YYCHK1(YYE)							     \
  do {									     \
    switch (YYE) {							     \
    default:								     \
      break;								     \
    case yyabort:							     \
      yystack.yyerrflag = 1;						     \
      goto yyDone;							     \
    case yyaccept:							     \
      yystack.yyerrflag = 0;						     \
      goto yyDone;							     \
    case yyerr:								     \
      goto yyuser_error;						     \
    }									     \
  } while (0)


/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
  yySymbol yytoken;
  yyGLRStack yystack;
  size_t yyposn;


  YYSTYPE* const yylvalp = &yylval;
  YYLTYPE* const yyllocp = &yylloc;

  yyinitGLRStack (&yystack, YYINITDEPTH);
  yystack.yytokenp = &yytoken;

  YYDPRINTF ((stderr, "Starting parse\n"));

  if (setjmp (yystack.yyexception_buffer) != 0)
    goto yyDone;

  yyglrShift (&yystack, 0, 0, 0, yyval_default, &yyloc_default);
  yytoken = YYEMPTY;
  yyposn = 0;

  while (yytrue)
    {
      /* For efficiency, we have two loops, the first of which is
	 specialized to deterministic operation (single stack, no
	 potential ambiguity).  */
      /* Standard mode */
      while (yytrue)
	{
	  yyRuleNum yyrule;
	  int yyaction;
	  const short* yyconflicts;

	  yyStateNum yystate = yystack.yytops.yystates[0]->yylrState;
          YYDPRINTF ((stderr, "Entering state %d\n", yystate));
	  if (yystate == YYFINAL)
	    goto yyDone;
	  if (yyisDefaultedState (yystate))
	    {
	      yyrule = yydefaultAction (yystate);
	      if (yyrule == 0)
		{
		  yyreportSyntaxError (&yystack, yylvalp, yyllocp);
		  goto yyuser_error;
		}
	      YYCHK1 (yyglrReduce (&yystack, 0, yyrule, yytrue));
	    }
	  else
	    {
	      if (yytoken == YYEMPTY)
		{
		  YYDPRINTF ((stderr, "Reading a token: "));
		  yychar = YYLEX;
		  yytoken = YYTRANSLATE (yychar);
                  YYDSYMPRINTF ("Next token is", yytoken, yylvalp, yyllocp);
		}
	      yygetLRActions (yystate, yytoken, &yyaction, &yyconflicts);
	      if (*yyconflicts != 0)
		break;
	      if (yyisShiftAction (yyaction))
		{
		  YYDPRINTF ((stderr, "Shifting token %s, ",
			      yytokenName (yytoken)));
		  if (yytoken != YYEOF)
		    yytoken = YYEMPTY;
		  yyposn += 1;
		  yyglrShift (&yystack, 0, yyaction, yyposn,
		              yylval, yyllocp);
		  if (0 < yystack.yyerrState)
		    yystack.yyerrState -= 1;
		}
	      else if (yyisErrorAction (yyaction))
		{
		  yyreportSyntaxError (&yystack, yylvalp, yyllocp);
		  goto yyuser_error;
		}
	      else
		YYCHK1 (yyglrReduce (&yystack, 0, -yyaction, yytrue));
	    }
	}

      while (yytrue)
	{
	  int yys;
	  int yyn = yystack.yytops.yysize;
	  for (yys = 0; yys < yyn; yys += 1)
	    YYCHK1 (yyprocessOneStack (&yystack, yys, yyposn,
				       yylvalp, yyllocp));
	  yytoken = YYEMPTY;
	  yyposn += 1;
	  yyremoveDeletes (&yystack);
	  if (yystack.yytops.yysize == 0)
	    {
	      yyundeleteLastStack (&yystack);
	      if (yystack.yytops.yysize == 0)
		yyFail (&yystack, "syntax error");
	      YYCHK1 (yyresolveStack (&yystack));
	      YYDPRINTF ((stderr, "Returning to deterministic operation.\n"));
	      yyreportSyntaxError (&yystack, yylvalp, yyllocp);
	      goto yyuser_error;
	    }
	  else if (yystack.yytops.yysize == 1)
	    {
	      YYCHK1 (yyresolveStack (&yystack));
	      YYDPRINTF ((stderr, "Returning to deterministic operation.\n"));
	      yycompressStack (&yystack);
	      break;
	    }
	}
      continue;
    yyuser_error:
      yyrecoverSyntaxError (&yystack, yylvalp, yyllocp);
      yyposn = yystack.yytops.yystates[0]->yyposn;
    }
 yyDone:
  ;

  yyfreeGLRStack (&yystack);
  return yystack.yyerrflag;
}

/* DEBUGGING ONLY */
static void yypstack (yyGLRStack* yystack, int yyk) ATTRIBUTE_UNUSED;
static void yypdumpstack (yyGLRStack* yystack) ATTRIBUTE_UNUSED;

static void
yy_yypstack (yyGLRState* yys)
{
  if (yys->yypred)
    {
      yy_yypstack (yys->yypred);
      fprintf (stderr, " -> ");
    }
  fprintf (stderr, "%d@%lu", yys->yylrState, (unsigned long) yys->yyposn);
}

static void
yypstates (yyGLRState* yyst)
{
  if (yyst == NULL)
    fprintf (stderr, "<null>");
  else
    yy_yypstack (yyst);
  fprintf (stderr, "\n");
}

static void
yypstack (yyGLRStack* yystack, int yyk)
{
  yypstates (yystack->yytops.yystates[yyk]);
}

#define YYINDEX(YYX) 							     \
    ((YYX) == NULL ? -1 : (yyGLRStackItem*) (YYX) - yystack->yyitems)


static void
yypdumpstack (yyGLRStack* yystack)
{
  yyGLRStackItem* yyp;
  size_t yyi;
  for (yyp = yystack->yyitems; yyp < yystack->yynextFree; yyp += 1)
    {
      fprintf (stderr, "%3lu. ", (unsigned long) (yyp - yystack->yyitems));
      if (*(bool*) yyp)
	{
	  fprintf (stderr, "Res: %d, LR State: %d, posn: %lu, pred: %ld",
		   yyp->yystate.yyresolved, yyp->yystate.yylrState,
		   (unsigned long) yyp->yystate.yyposn,
		   (long) YYINDEX (yyp->yystate.yypred));
	  if (! yyp->yystate.yyresolved)
	    fprintf (stderr, ", firstVal: %ld",
		     (long) YYINDEX (yyp->yystate.yysemantics.yyfirstVal));
	}
      else
	{
	  fprintf (stderr, "Option. rule: %d, state: %ld, next: %ld",
		   yyp->yyoption.yyrule,
		   (long) YYINDEX (yyp->yyoption.yystate),
		   (long) YYINDEX (yyp->yyoption.yynext));
	}
      fprintf (stderr, "\n");
    }
  fprintf (stderr, "Tops:");
  for (yyi = 0; yyi < yystack->yytops.yysize; yyi += 1)
    fprintf (stderr, "%lu: %ld; ", (unsigned long) yyi,
	     (long) YYINDEX (yystack->yytops.yystates[yyi]));
  fprintf (stderr, "\n");
}


#line 780 "../standalone/parser.y"


