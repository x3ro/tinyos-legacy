{
open Parse
exception Eof
}
rule token = parse
    [' ' '\t' '\n']     { token lexbuf }     (* skip blanks *)
  | ['0'-'9']+ as lxm { INT (int_of_string lxm) }
  | "select"	   { SELECT }
  | "where"	   { WHERE }
  | "interval"	   { INTERVAL }
  | ','		   { SCOMMA }
  | '<'		   { SLT }
  | "<="	   { SLE }
  | '>'		   { SGT }
  | ">="	   { SGE }
  | '='		   { SEQ }
  | "<>"	   { SNE }
  | "and"	   { SAND }
  | "or"	   { SOR }
  | "not"	   { SNOT }
  | '('		   { OPAREN }
  | ')'		   { CPAREN }
  | '['		   { OPAREN2 }
  | ']'		   { CPAREN2 }
  | ['A'-'Z' 'a'-'z']['A'-'Z' 'a'-'z' '0'-'9']* as id { ID id }
  | eof            { raise Eof }
