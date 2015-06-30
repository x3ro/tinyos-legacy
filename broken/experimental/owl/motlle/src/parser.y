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
%}

%union {
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
}

%token FUNCTION IF ELSE WHILE FOR ASSIGN QUOTE BREAK CONTINUE RETURN
%token INTEGER STRING SYMBOL FLOAT BIGINT SINK SWITCH CASE DEFAULT
%token ELLIPSIS INCREMENTER DO
%token MODULE LIBRARY IMPORTS DEFINES READS WRITES OP_ASSIGN



%right '.'
%left XOR
%left SC_OR OR
%left SC_AND AND
%left EQ NE LT LE GT GE
%left '|' '^'
%left '&'
%left SHIFT_LEFT SHIFT_RIGHT
%left '+' '-'
%left '*' '/' '%'
%left NOT '~' UMINUS

%type <tclist> stmt_list stmt_list1 call_list call_list1
%type <tcomponent> stmt stmt1 decl_or_stmt decl_or_stmt1 optional_expression expression e0 e1 e2 for exit match
%type <tcomponent> function_call array_ref code_block function_decl
%type <tcomponent> control_statement opt_match_condition variable_decl
%type <tcomponent> if while dowhile optional_else function_body1 function_body2
%type <tcomponent> control_expression eif function_expression
%type <tvlist> variable_list plist plist1
%type <tvlist> imports defines reads writes 
%type <tvlist> variable_init_list variable_init
%type <tparameters> parameters
%type <tmtype> type optional_type
%type <string> optional_help STRING
%type <symbol> variable SYMBOL label optional_symbol
%type <symbol> variable_name
%type <integer> INTEGER
%type <mudlle_float> FLOAT
%type <tconstant> constant simple_constant optional_constant_tail table_entry
%type <tconstant> string_constant
%type <tblock> motlle_code_block
%type <tcstlist> constant_list optional_constant_list table_entry_list
%type <tfile> entry_types simple module library
%type <tpattern> pattern pattern_list pattern_array pattern_atom 
%type <tpattern> opt_pattern_list_tail pattern_atom_expr pattern_case
%type <tpatternlist> opt_pattern_sequence pattern_sequence
%type <tmatchnode> match_node
%type <tmatchcond> match_pattern match_patterns
%type <tmatchnodelist> match_list
%type <operator> OP_ASSIGN INCREMENTER

%glr-parser

%{

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

%}

%%

start : { lstack = NULL; } entry_types { parsed_code = $2; } ;

entry_types :
  simple |
  library |
  module ;

simple : stmt_list 
 { $$ = new_file(parser_memory, f_plain, NULL, NULL, NULL, NULL, NULL, $1); } |
 expression 
 { $$ = new_file(parser_memory, f_plain, NULL, NULL, NULL, NULL, NULL, new_clist(parser_memory, $1, NULL)); } ;

module : MODULE optional_symbol imports reads writes '[' stmt_list ']' optional_semi
  { $$ = new_file(parser_memory, f_module, $2, $3, NULL, $4, $5, $7); } ;

library : LIBRARY SYMBOL imports defines reads writes '[' stmt_list ']' optional_semi
  { $$ = new_file(parser_memory, f_library, $2, $3, $4, $5, $6, $8); } ;

optional_symbol :
  SYMBOL |
  /* empty */ { $$ = NULL; } ;

imports : 
  IMPORTS variable_list { $$ = $2; } |
  /* empty */ { $$ = NULL; } ;

defines : 
  DEFINES variable_list { $$ = $2; } ;

reads : 
  READS variable_list { $$ = $2; } |
  /* empty */ { $$ = NULL; } ;

writes : 
  WRITES variable_list { $$ = $2; } |
  /* empty */ { $$ = NULL; } ;

stmt_list : stmt_list1 { $$ = reverse_clist($1); } ;

stmt_list1 :
  stmt_list1 decl_or_stmt { $$ = new_clist(parser_memory, $2, $1); } |
  decl_or_stmt { $$ = new_clist(parser_memory, $1, NULL); } ;

optional_semi : /* empty */ | ';' ;

stmt : 
  label stmt { $$ = new_component(parser_memory, c_labeled, $1, $2); } |
  stmt1 ;

decl_or_stmt :
  label decl_or_stmt { $$ = new_component(parser_memory, c_labeled, $1, $2); } |
  decl_or_stmt1 ;

decl_or_stmt1 : 
  control_statement | 
  expression ';' { $$ = $1; } |
  ';' { $$ = component_undefined; } |
  variable_decl |
  function_decl |
  code_block ;

stmt1 : 
  control_statement |
  expression ';' { $$ = $1; } |
  ';' { $$ = component_undefined; } |
  code_block ;

expression : 
  control_expression |
  e0 ;

optional_expression :
  expression |
  /* empty */ { $$ = NULL; } ;
 
label : SYMBOL ':' { $$ = $1; } ;

e0 :
  pattern ASSIGN expression { $$ = new_pattern_component(parser_memory, $1, $3); } |
  function_expression |
  variable ASSIGN expression { $$ = new_component(parser_memory, c_assign, $1, $3); } |
  variable OP_ASSIGN expression {
      $$ = new_component(parser_memory, c_assign,
			 $1, make_binary($2,
					 new_component(parser_memory, c_recall, $1),
					 $3));
  } |
  e2 '[' expression ']' ASSIGN expression
    { $$ = new_component(parser_memory, c_builtin, b_set, 3, $1, $3, $6); } |
  e2 '[' expression ']' OP_ASSIGN expression {
    $$ = make_ref_set_increment($1, $3, $5, $6, 0);
  } |
  e1 ;

control_statement : if | while | dowhile | for | exit | match ;

control_expression: eif ;

if : 
  IF '(' expression ')' stmt optional_else 
    {
      if ($6)
        $$ = new_component(parser_memory, c_builtin, b_ifelse, 3, $3, $5, $6);
      else
        $$ = new_component(parser_memory, c_builtin, b_if, 2, $3, $5);
    } ;		

optional_else : 
  /* empty */ { $$ = NULL; } |
  ELSE stmt { $$ = $2; } ;

eif :
  IF '(' expression ')' expression ELSE expression {
    $$ = new_component(parser_memory, c_builtin, b_ifelse, 3, $3, $5, $7);
  } ;

while : 
  WHILE '(' expression ')' stmt
    {
      $$ = new_component(parser_memory, c_builtin, b_while, 2, $3, $5);
    } ;

dowhile : 
  DO stmt WHILE '(' expression ')' ';'
    {
      $$ = new_component(parser_memory, c_builtin, b_dowhile, 2, $2, $5);
    } ;

for :
  FOR '(' optional_expression ';' optional_expression ';' 
    optional_expression ')' stmt
    {
      $$ = new_component(parser_memory, c_builtin, b_for, 4, $3, $5, $7, $9);
    } |
  FOR '(' variable_decl optional_expression ';' 
    optional_expression ')' stmt
    {
      $$ = new_component(parser_memory, c_builtin, b_for, 4, $3, $4, $6, $8);
    } ;


match :
  SWITCH '(' expression ')' '{' match_list '}' {
    $$ = new_match_component(parser_memory, $3, $6);
  } ;

match_list :
  match_node { $$ = new_match_list(parser_memory, $1, NULL); } |
  match_list match_node { $$ = new_match_list(parser_memory, $2, $1); } ;

opt_match_condition :
  /* nothing */ { $$ = NULL; } |
  IF '(' expression ')' { $$ = $3; } ;

match_node :
  match_patterns stmt_list {
    $$ = new_matchnode(parser_memory, $1, $2); 
  } |
  DEFAULT ':' stmt_list {
    $$ = new_matchnode(parser_memory, NULL, $3);
  } ;

match_patterns :
  match_pattern match_patterns { $1->next = $2; $$ = $1; } |
  match_pattern ;

match_pattern :
  CASE pattern_case opt_match_condition ':' {
    $$ = new_matchcond(parser_memory, $2, $3, NULL);
  } ;

exit :
  BREAK SYMBOL expression ';' { 
    $$ = new_component(parser_memory, c_exit, $2, $3); } |
  BREAK SYMBOL ';' { 
    $$ = new_component(parser_memory, c_exit, $2, component_undefined); } |
  BREAK ';' { 
    $$ = new_component(parser_memory, c_exit, NULL, component_undefined); } |
  CONTINUE ';' { 
    $$ = new_component(parser_memory, c_continue, NULL); } |
  CONTINUE SYMBOL ';' { 
    $$ = new_component(parser_memory, c_continue, $2); } |
  RETURN expression ';' { 
    $$ = new_component(parser_memory, c_exit, "<return>", $2); } |
  RETURN ';' { 
    $$ = new_component(parser_memory, c_exit, "<return>", component_undefined); } ;


function_expression :
  optional_type FUNCTION { lpush(lexloc); } parameters optional_help
  function_body1 { $$ = make_function($1, $5, $4, $6); } ;

optional_help :
  /* empty */ { $$ = NULL; } |
  STRING ;

parameters : 
  '(' plist ')' { $$.varargs = FALSE; $$.args = $2; } |
  variable_name { $$.varargs = TRUE; $$.var = $1; } ;

plist :
  /* empty */ { $$ = NULL; } |
  plist1 { $$ = reverse_vlist($1); };

plist1 :
  plist1 ',' type variable_name { $$ = new_vlist(parser_memory, $4, $3, NULL, $1); } |
  plist1 ',' variable_name { $$ = new_vlist(parser_memory, $3, stype_any, NULL, $1); } |
  type variable_name { $$ = new_vlist(parser_memory, $2, $1, NULL, NULL); } |
  variable_name { $$ = new_vlist(parser_memory, $1, stype_any, NULL, NULL); } ;

optional_type :
  /* empty */ { $$ = stype_any; } |
  type ;

type :
  SYMBOL { $$ = find_type($1); } ;

e1 :
  e1 '.' e1 { $$ = make_binary(b_cons, $1, $3); } |
  e1 XOR e1 { $$ = make_binary(b_xor, $1, $3); } |
  e1 SC_OR e1 { $$ = make_binary(b_sc_or, $1, $3); } |
  e1 SC_AND e1 { $$ = make_binary(b_sc_and, $1, $3); } |
  e1 EQ e1 { $$ = make_binary(b_eq, $1, $3); } |
  e1 NE e1 { $$ = make_binary(b_ne, $1, $3); } |
  e1 LT e1 { $$ = make_binary(b_lt, $1, $3); } |
  e1 LE e1 { $$ = make_binary(b_le, $1, $3); } |
  e1 GT e1 { $$ = make_binary(b_gt, $1, $3); } |
  e1 GE e1 { $$ = make_binary(b_ge, $1, $3); } |
  e1 '|' e1 { $$ = make_binary(b_bitor, $1, $3); } |
  e1 '^' e1 { $$ = make_binary(b_bitxor, $1, $3); } |
  e1 '&' e1 { $$ = make_binary(b_bitand, $1, $3); } |
  e1 SHIFT_LEFT e1 { $$ = make_binary(b_shift_left, $1, $3); } |
  e1 SHIFT_RIGHT e1 { $$ = make_binary(b_shift_right, $1, $3); } |
  e1 '+' e1 { $$ = make_binary(b_add, $1, $3); } |
  e1 '-' e1 { $$ = make_binary(b_subtract, $1, $3); } |
  e1 '*' e1 { $$ = make_binary(b_multiply, $1, $3); } |
  e1 '/' e1 { $$ = make_binary(b_divide, $1, $3); } |
  e1 '%' e1 { $$ = make_binary(b_remainder, $1, $3); } |
  '-' e1 %prec UMINUS { $$ = make_unary(b_negate, $2); } |
  NOT e1  { $$ = make_unary(b_not, $2); } |
  '~' e1  { $$ = make_unary(b_bitnot, $2); } |
  INCREMENTER variable {
    $$ = new_component
      (parser_memory, c_assign, 
       $2, 
       make_binary($1,
		   new_component(parser_memory, c_recall, $2),
		   new_component(parser_memory, c_constant,
				 new_constant(parser_memory, cst_int, 1))));
  } |
  variable INCREMENTER { 
    $$ = new_postfix_inc_component(parser_memory, $1, $2); } |
  INCREMENTER e2 '[' expression ']' {
    $$ = make_ref_set_increment
      ($2, $4, $1,
       new_component(parser_memory, c_constant,
		     new_constant(parser_memory, cst_int, 1)),
       0);
  } |
  e2 '[' expression ']' INCREMENTER {
    $$ = make_ref_set_increment
      ($1, $3, $5,
       new_component(parser_memory, c_constant,
		     new_constant(parser_memory, cst_int, 1)),
       1);
  } |
  e2 ;

e2 :
  function_call |
  array_ref |
  variable { $$ = new_component(parser_memory, c_recall, $1); } |
  simple_constant { $$ = new_component(parser_memory, c_constant, $1); } |
  QUOTE constant { $$ = new_component(parser_memory, c_constant, $2); } |
  '(' expression ')' { $$ = $2; } |
  '(' code_block ')' { $$ = $2; } ;

array_ref :
  e2 '[' expression ']'
    { $$ = new_component(parser_memory, c_builtin, b_ref, 2, $1, $3); } ;

function_call :
  e2 '(' call_list ')'
    { $$ = new_component(parser_memory, c_execute, new_clist(parser_memory, $1, $3)); } ;

call_list :
  /* empty */ { $$ = NULL; } |
  call_list1 { $$ = reverse_clist($1); } ;

call_list1 :
  call_list1 ',' expression { $$ = new_clist(parser_memory, $3, $1); } |
  expression { $$ = new_clist(parser_memory, $1, NULL); } ;

constant :
  simple_constant |
  '{' table_entry_list '}' { $$ = new_constant(parser_memory, cst_table, $2); } |
  '{' '}' { $$ = new_constant(parser_memory, cst_table, NULL); } |
  '[' optional_constant_list ']' { $$ = new_constant(parser_memory, cst_array, $2); } |
  '(' constant_list optional_constant_tail ')' { 
    $$ = new_constant(parser_memory, cst_list, new_cstlist(parser_memory, $3, $2));
  } |
  '(' ')' { $$ = new_constant(parser_memory, cst_list, NULL); } ;

optional_constant_tail :
  /* empty */ { $$ = NULL; } |
  '.' constant { $$ = $2; } ;

simple_constant :
  string_constant |
  INTEGER { $$ = new_constant(parser_memory, cst_int, $1); } |
  FLOAT { $$ = new_constant(parser_memory, cst_float, $1); } ;

string_constant :
  STRING { $$ = new_constant(parser_memory, cst_string, $1); } ;

optional_constant_list :
  /* empty */ { $$ = NULL; } |
  constant_list;

constant_list :
  constant { $$ = new_cstlist(parser_memory, $1, NULL); } |
  constant_list constant { $$ = new_cstlist(parser_memory, $2, $1); } ;

table_entry_list :
  table_entry { $$ = new_cstlist(parser_memory, $1, NULL); } |
  table_entry_list table_entry { $$ = new_cstlist(parser_memory, $2, $1); } ;

table_entry :
  string_constant ASSIGN constant { 
    $$ = new_constant(parser_memory, cst_symbol, 
		      new_cstpair(parser_memory, $1, $3));
  } ;

pattern :
  pattern_list |
  pattern_array ;

pattern_case :
  expression { $$ = new_pattern_expression(parser_memory, $1); } |
  '@' pattern_atom { $$ = $2; } ;

pattern_atom :
  pattern |
  SINK { $$ = new_pattern_sink(parser_memory); } |
  variable { $$ = new_pattern_symbol(parser_memory, $1, stype_any); } |
  simple_constant { $$ = new_pattern_constant(parser_memory, $1); } |
  ',' pattern_atom_expr { $$ = $2; } ;

pattern_atom_expr :
  variable { 
    $$ = new_pattern_expression(parser_memory, 
				new_component(parser_memory, c_recall, $1));
  } |
  '(' expression ')' { $$ = new_pattern_expression(parser_memory, $2); } ;

pattern_sequence :
  pattern_atom { $$ = new_pattern_list(parser_memory, $1, NULL); } |
  pattern_sequence pattern_atom { $$ = new_pattern_list(parser_memory, $2, $1); } ;

opt_pattern_sequence :
  /**/ { $$ = NULL; } |
  pattern_sequence ;

opt_pattern_list_tail :
  /**/ { $$ = NULL; } |
  '.' pattern_atom { $$ = $2; } ;

pattern_list :
  '(' pattern_sequence opt_pattern_list_tail ')' { 
    $$ = new_pattern_compound(parser_memory, pat_list, 
			      new_pattern_list(parser_memory, $3, $2), 0);
  } |
  '(' ')' { $$ = new_pattern_compound(parser_memory, pat_list, NULL, 0); } ;

pattern_array :
  '[' opt_pattern_sequence ELLIPSIS ']' { 
    $$ = new_pattern_compound(parser_memory, pat_array, $2, 1); 
  } |
  '[' opt_pattern_sequence ']' {
    $$ = new_pattern_compound(parser_memory, pat_array, $2, 0);
  } ;

variable :
  SYMBOL ;

variable_name :
  SYMBOL ;

code_block :
  motlle_code_block { $$ = new_component(parser_memory, c_block, $1); } ;


motlle_code_block :
  '{' stmt_list '}' { 
    $$ = new_codeblock(parser_memory, NULL, $2);
  } ;

variable_decl :
  type variable_init_list ';' { 
    set_vlist_types($2, $1);
    $$ = new_component(parser_memory, c_decl, reverse_vlist($2));
  } ;

variable_list :
  variable_list ',' variable_name { 
    $$ = new_vlist(parser_memory, $3, stype_any, NULL, $1); } |
  variable_name { 
    $$ = new_vlist(parser_memory, $1, stype_any, NULL, NULL); } ;

function_decl :
  type variable { lpush(lexloc); } parameters optional_help 
    function_body2 { $$ = make_function_decl($1, $2, $5, $4, $6); } ;

function_body1 : 
  expression |
  code_block ;

function_body2 : 
  expression ';' { $$ = $1 } |
  code_block ;

variable_init_list :
  variable_init_list ',' variable_init { $$ = $3; $$->next = $1; } |
  variable_init { $$ = $1 } ;

variable_init :
  variable_name { $$ = new_vlist(parser_memory, $1, stype_any, NULL, NULL); } |
  variable_name ASSIGN expression { $$ = new_vlist(parser_memory, $1, stype_any, $3, NULL); } ;

%%
