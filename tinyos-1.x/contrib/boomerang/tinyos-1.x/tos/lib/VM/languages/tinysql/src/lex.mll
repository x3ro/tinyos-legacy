(*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *)
{
open Parse
open Sql
exception Eof
let lastpos = ref Lexing.dummy_pos
let lasttoken = ref ""
let savepos lb = 
  lastpos := Lexing.lexeme_start_p lb;
  lasttoken := Lexing.lexeme lb  
}
rule token = parse
    [' ' '\t' '\n']     { token lexbuf }     (* skip blanks *)
  | ['0'-'9']+ as lxm { savepos lexbuf; INT (int_of_string lxm) }
  | "select"	   { savepos lexbuf; SELECT }
  | "where"	   { savepos lexbuf; WHERE }
  | "interval"	   { savepos lexbuf; INTERVAL }
  | "sample"' '+"period" { savepos lexbuf; INTERVAL }
  | ','		   { savepos lexbuf; SCOMMA }
  | '<'		   { savepos lexbuf; SLT }
  | "<="	   { savepos lexbuf; SLE }
  | '>'		   { savepos lexbuf; SGT }
  | ">="	   { savepos lexbuf; SGE }
  | '='		   { savepos lexbuf; SEQ }
  | "<>"	   { savepos lexbuf; SNE }
  | "and"	   { savepos lexbuf; SAND }
  | "or"	   { savepos lexbuf; SOR }
  | "not"	   { savepos lexbuf; SNOT }
  | '('		   { savepos lexbuf; OPAREN }
  | ')'		   { savepos lexbuf; CPAREN }
  | '['		   { savepos lexbuf; OPAREN2 }
  | ']'		   { savepos lexbuf; CPAREN2 }
  | ['A'-'Z' 'a'-'z']['A'-'Z' 'a'-'z' '0'-'9']* as id { savepos lexbuf; ID id }
  | eof            { raise Eof }
