(*
 * counter.ml
 *
 * This file contains a CIL transformation that increments a counter
 * at the beginning of each basic block.
 *)

open Cil

let max_motes = 10000;;  (* Waste RAM, but who cares? It's only a few megs. *)

let num_bbs = ref 0;;
let cur_bb = ref 0;;

let myType = Formatcil.cType 
	       "int [%d:motes][%d:bbs]" 
	       [("motes", Fd max_motes); ("bbs",Fd !num_bbs) ];;

let cntArr = makeGlobalVar "bb_count" myType;; (* (TArray(intType, Some (integer !num_bbs),[]));; *)

(* Just count the number of basic blocks in the file *)
class countbbClass = object
  inherit nopCilVisitor

  method vstmt (s: stmt) : stmt visitAction = begin
    begin
      match s.skind with
	Instr instrs ->
	  num_bbs := !num_bbs + 1; 
      | _ -> ()
    end;
    DoChildren
  end
end

  
class instrumentClass = object
  inherit nopCilVisitor

  method vstmt (s: stmt) : stmt visitAction = begin
    begin
      match s.skind with
	  Instr instrs ->  begin
	    cur_bb := !cur_bb + 1;
	    print_string (string_of_int(!cur_bb) ^ "\t");
	    print_string (Pretty.sprint 76 (d_thisloc ()) );
	    print_string "\n";


	    (* Want "bb_count[" ^ string_of_int(!cur_bb) ^ "] =  bb_count[!cur_bb] + 1;" *)
	     let ctrInc = Formatcil.cInstr 
			    "%v:arr[%d:mote][%d:cnt] = %v:arr[%d:mote][%d:cnt] + 1; // BB # %d:cnt" 
			    locUnknown  
			    [ ("mote", Fd 42); 
			      ("cnt",Fd !cur_bb); 
			      ("arr", Fv cntArr)
			    ]; 

(*	    let ctrInc =
	      Set (var ctrVar,
		 BinOp (PlusA, Lval (var ctrVar), integer 1, intType),
		 locUnknown)
	      Set (var ctrVar,
		   BinOp (PlusA, Lval (var ctrVar), integer !cur_bb, intType),
		   locUnknown) *)
	    in
	      s.skind <- Instr (ctrInc :: instrs);
	  end
	| _ -> ()
    end;
    DoChildren
  end
end


let main (f: file) : unit = 
  visitCilFile ((new countbbClass) :> cilVisitor) f;

(*  print_string("DEBUG: There are " ^ string_of_int(!num_bbs) ^ " basic blocks\n"); *)

(*  f.globals <- GVarDecl (ctrVar, locUnknown) :: f.globals; *)

  visitCilFile ((new instrumentClass) :> cilVisitor) f;
  f.globals <- GVarDecl (cntArr, locUnknown) :: f.globals


let feature : featureDescr = {
  fd_name = "Counter";
  fd_enabled = ref false;
  fd_description = "increment a counter at the beginning of each basic block";
  fd_extraopt = [];
  fd_doit = main;
  fd_post_check = true;
  } 

