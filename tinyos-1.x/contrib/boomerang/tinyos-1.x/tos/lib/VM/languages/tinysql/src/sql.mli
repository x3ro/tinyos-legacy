(*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *)
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
