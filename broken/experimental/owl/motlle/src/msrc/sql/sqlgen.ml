open Sql
open List
open String
open Char
open Printf
open Hashtbl

let optionfn none some = function
   None -> none
 | Some c -> some c

let present = function
    None -> false
  | Some _ -> true

let indent n = make n ' '

let relname = function
   LT -> "<"
 | LE -> "<="
 | GT -> ">"
 | GE -> ">="
 | EQ -> "=="
 | NE -> "!="

let boolname = function
   AND -> "&&"
 | OR -> "||"

let rec valprint = function 
   Attribute s -> s
 | Number n -> string_of_int n
 | Op (name, args, _) -> sprintf "%s(%s)" name (concat ", " (map valprint args))
 | GOp (name, args, _) -> sprintf "%s[%s]" name (concat ", " (map valprint args))


let rec cprint = function
   Rel (op, v1, v2) -> sprintf "(%s %s %s)" (valprint v1) (relname op) (valprint v2)
 | Bool (op, c1, c2) -> sprintf "(%s %s %s)" (cprint c1) (boolname op) (cprint c2)
 | Not c -> sprintf "!%s" (cprint c)

let condprint = optionfn "" (function c -> " WHERE " ^ cprint c)

let sqlprint { fields = f; cond = c; interval = i } =
  printf "// SELECT %s%s INTERVAL %d\n" 
    (concat ", " (map valprint f)) 
    (condprint c) i

let sqlheader interval global vars msgvars = 
  printf "mhop_set_update(%d); settimer0(%d);\n" 
    (interval * 2) (interval * 10);
  if global then begin
    printf "mhop_set_forwarding(0);\n";
    printf "
snoop = fn () snoop_epoch(decode(snoop_msg(), vector(2))[0]);
intercept = fn () 
  {
    vector fields = decode(intercept_msg(), vector(%s));

    snoop_epoch(fields[0]);
"
      (let fieldsizes = map (function f -> (find vars f).size) msgvars
       in (concat ", " ("2" :: fieldsizes)));

    let evil = ref 1 in
      let genintercept s = 
        let index = !evil in
          begin
            evil := index + 1;
	    s index
	  end
      in
        List.iter (function f -> printf "    %s;\n" 
                                   (genintercept ((find vars f).intercept)))
	          msgvars;
    printf "  };\n";
    printf "epoch_change = fn ()\n  {\n";
    List.iter (function f -> printf "    %s;\n" ((find vars f).newepoch))
	      msgvars;
    printf "  };\n"
  end else
    (* non-global case *)
    printf "mhop_set_forwarding(1);\n";
    print_string "
snoop = fn () heard(snoop_msg());
intercept = fn () heard(intercept_msg());
heard = fn (msg) snoop_epoch(decode(msg, vector(2))[0]);
";
  print_string "\n"

let valuse = function 
   Attribute s -> "v_" ^ s
 | Number n -> string_of_int n
 | Op (_, _, gen) -> "v_" ^ gen
 | GOp (_, _, gen) -> "v_" ^ gen

let valvars = function 
   Attribute s -> [s]
 | Number n -> []
 | Op (_, _, gen) -> [gen]
 | GOp (_, _, gen) -> [gen]

let make_genlocal init get = { init = init; get = get; size = "2"; update = ""; newepoch = ""; intercept = function n -> "" }

let valattrs vars ops = 
  let rec vattrs = function
     Attribute s -> 
        if mem vars s then [] 
	else (let attrget = s ^ "()" in
	  add vars s (make_genlocal None attrget);
	  [s])
   | Op (name, args, gen) ->
	Hashtbl.replace ops name ();        
        let vargs = flatten (map vattrs args) 
	and (cst, noncst) =
	   partition (function Number _ -> true | _ -> false) args
	and statename = "s_" ^ gen
	in let getargs = (concat ", " (statename :: (map valuse noncst)))
	   and makeargs = (concat ", " (map valuse cst)) in
	     add vars gen (make_genlocal
			     (Some (sprintf "%s = %s_make(%s)" statename
							      name
							      makeargs))
			     (sprintf "%s_get(%s)" name getargs));
             vargs @ [gen]
   | GOp (name, args, gen) ->
	Hashtbl.replace ops name ();        
        let vargs = flatten (map vattrs args) 
	and (cst, noncst) =
	   partition (function Number _ -> true | _ -> false) args
	and statename = "s_" ^ gen
	in let getargs = (concat ", " (statename :: (map valuse noncst)))
	   and makeargs = (concat ", " (map valuse cst)) in
          let code = { init = Some (sprintf "%s = %s_make(%s)" statename
							      name
							      makeargs);
		      get = sprintf "%s_get(%s)" name statename;
		      size = name ^ "_buffer()";
		      update = sprintf "%s_update(%s)" name getargs;
		      intercept = sprintf "%s_intercept(%s, fields[%d])" name statename;
		      newepoch = sprintf "%s_newepoch(%s)" name statename } in
	     add vars gen code;
             vargs
   | _ -> []
  in vattrs

let cattrs vars ops =
  let rec cf = function
     Rel (_, v1, v2) -> (valattrs vars ops v1) @ (valattrs vars ops v2)
   | Bool (_, c1, c2) -> (cf c1) @ (cf c2)
   | Not c -> cf c
  in cf

let condattrs vars ops = optionfn [] (cattrs vars ops)

let rec cc = function
   Rel (op, v1, v2) -> sprintf "(%s %s %s)" (valuse v1) (relname op) (valuse v2)
 | Bool (op, c1, c2) -> sprintf "(%s %s %s)" (cc c1) (boolname op) (cc c2)
 | Not c -> sprintf "!%s" (cc c)

let condcompile afterif = optionfn "" 
   (function cond -> sprintf "if (%s)%s" (cc cond) afterif)

let getprint ind vars vlist =
  let prefix = indent ind in
  List.iter (function v -> let { get = g } = find vars v in 
	                      printf "%sany v_%s = %s;\n" prefix v g)
	    vlist

let print_update ind vars msgvars =
  let prefix = indent ind in
  List.iter (function v -> printf "%s%s;\n" prefix ((find vars v).update)) msgvars

let sqlsend fields cond global vars msgvars allvars =
  List.iter (function v -> match (find vars v) with
     { init = None } -> ()
   | { init = Some create } -> printf "%s;\n" create)
     (if global then allvars @ msgvars else allvars);
  printf "Timer0 = fn () \n";
  if global then
    begin
      print_string "  {\n";
      print_string "    if (id()) {\n";
      getprint 6 vars allvars;
      print_string "\n      next_epoch();\n";
      if present cond then
        begin
          printf "      %s" (condcompile " {\n" cond);
	  print_update 8 vars msgvars;
          print_string "      };\n"
	end
      else
	print_update 6 vars msgvars;
      print_string "    };\n";
      print_string "    {\n";
      getprint 6 vars msgvars;
      print_string "\n      ";
    end
  else 
    begin
      print_string "  if (id()) {\n";
      getprint 4 vars allvars;
      print_string "\n    next_epoch();\n";
      printf "    %s" (condcompile "\n      " cond);
    end;
  printf "mhopsend(encode(vector(epoch(), %s)))\n" 
    (concat ", " (map valuse fields));
  if global then
    print_string "    }\n";
  print_string "  };\n"

let loadcode opname = 
  try
    let rec fd = open_in (opname ^ ".mud") 
    and dumpfd f = 
      try
        printf "%s\n" (input_line f);
	dumpfd f
      with End_of_file -> ()
    in
      dumpfd fd;
      close_in_noerr fd
  with Sys_error n -> ()

let sqlimport ops = 
    Hashtbl.iter (function op -> function _ -> printf "// uses %s\n" op;
		  loadcode op) ops

let sqlgen { fields = f; cond = c; interval = i; global = g } =
  let vars = Hashtbl.create 16 
  and ops = Hashtbl.create 16 in
    let fvars = flatten (map (valattrs vars ops) f)
    and msgvars = flatten (map valvars f) 
    and cvars = condattrs vars ops c in
      let allvars = fvars @ cvars in
        sqlimport ops;
        sqlheader i g vars msgvars;
	sqlsend f c g vars msgvars allvars

let lowercase_stdin s n =
  let count = input stdin s 0 n in
    begin 
      for i = 0 to count - 1 do
        s.[i] <- lowercase (s.[i])
      done
    end;
    count

let _ = 
  try
    let lexbuf = Lexing.from_function lowercase_stdin in
      let result = Parse.main Lex.token lexbuf in
        sqlprint result;
        sqlgen result
  with Lex.Eof ->
    print_string "oops"; exit 0
