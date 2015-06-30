%{
(*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *)
open Sql
let newopname = 
  let count = ref 0
    in function () -> count := !count + 1; "op" ^ string_of_int !count
%}

%token <int> INT
%token <string> ID
%token SELECT WHERE INTERVAL
%token SCOMMA SAND SOR SNOT SLT SLE SGT SGE SEQ SNE OPAREN CPAREN OPAREN2 CPAREN2
%type <Sql.query> main
%type <Sql.value list> fields gfields
%type <Sql.value> field value
%type <Sql.condition option> condition_opt
%type <Sql.condition> condition condition1 condition2 condition3
%type <Sql.relop> relop
%type <Sql.value list> vlist

%left SOR
%left SAND
%nonassoc SNOT

%start main

%%

main:
	SELECT fields condition_opt INTERVAL INT 
	  { { fields = List.rev $2; cond = $3; interval = $5; global = false } }
      | SELECT gfields condition_opt INTERVAL INT 
	  { { fields = List.rev $2; cond = $3; interval = $5; global = true } }
      ;

fields:
	fields SCOMMA field { $3::$1 }
      | field { [$1] }
      ;

gfields:
	gfields SCOMMA gfield { $3::$1 }
      | gfield { [$1] }
      ;

field: value { $1 } ;

gfield: ID OPAREN2 vlist CPAREN2 { GOp ($1, List.rev $3, newopname()) } ;


condition_opt:
	WHERE condition { Some $2 }
      | /* empty */     { None }
      ;

condition: 
        condition SOR condition { Bool (OR, $1, $3) }
      | condition1 { $1 }
      ;

condition1: 
	condition1 SAND condition1 { Bool (AND, $1, $3) }
      | condition2 { $1 }
      ;

condition2: 
	SNOT condition2 { Not $2 }
      | condition3 { $1 }
      ;

condition3: 
	value relop value { Rel ($2, $1, $3) }
      | OPAREN condition CPAREN { $2 }
      ;

value: 
	ID { Attribute $1 }
      | INT { Number $1 }
      | ID OPAREN vlist CPAREN { Op ($1, List.rev $3, newopname()) }
      ;

vlist:
	value { [$1] }
      | vlist SCOMMA value { $3::$1 }
      ;

relop: SLT { LT } | SLE { LE } | SGT { GT } | SGE { GE } | SEQ { EQ } | SNE { NE } ;
