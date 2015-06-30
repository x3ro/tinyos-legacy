type 
  value = Attribute of string | 
  	  Number of int |
	  Op of (string * value list * string) |
	  GOp of (string * value list * string)
and
  relop = LT | LE | GT | GE | EQ | NE
and
  boolop = AND | OR
and
  condition = Rel of relop * value * value | 
	      Bool of boolop * condition * condition |
	      Not of condition
and
  query = { fields: value list; cond: condition option; interval: int; 
	    global: bool }
and
  genexpr = { init: string option; update: string; get: string;
              intercept: int -> string; size: string; newepoch: string }
