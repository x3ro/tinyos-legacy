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

#include "mudlle.h"
#include "ins.h"
#include "code.h"
#include "alloc.h"
#include "runtime/runtime.h"
#include "interpret.h"
#include "compile.h"
#include <string.h>
#include <stddef.h>

/* Instruction lists are stored in reverse order, to simplify creation.
   They are reversed before use ...
*/

struct _ilist		/* Instruction list */
{
  struct _ilist *next;
  instruction ins;
  u16 arg;
  u8 argsize;
  u8 *cvars;			/* closure vars for OPmclosure */
  struct local_value *cst;
  label lab;			/* The main label for this instruction.
				   All other labels are aliases of this one. */
  bool label_used;
  label to;			/* Destination of branches */
  u32 offset;			
};

typedef struct _blocks
{
  struct _blocks *next;
  const char *name;
  label exitlab;		/* Label for block exit */
  bool mcontinue;		/* TRUE for blocks for continue */
  bool discard;			/* TRUE if block has no result */
  i16 stack_depth;		/* Stack depth at block entry */
} *blocks;

struct _fncode
{
  location l;
  ilist instructions;
  ilist *last_ins;
  i16 current_depth, max_depth; /* This tracks the stack depth as
				    determined by the instructions */
  int loopcount;
  i8 nargs;
  label next_label;		/* For the 'label' function */
  struct gcpro_list cstpro;	/* Protect csts list */
  valuelist csts;		/* Constants of this function */
  blocks blks;			/* Stack of named blocks */
  int toplevel;
  block_t fnmemory;
  struct global_state *gstate;	/* Global state for which this function is
				   being compiled */
};

struct _label			/* A pointer to an instruction */
{
  ilist ins;			/* The instruction this label points to */
  label alias;			/* This label is actually an alias for
				   another label ... */
};

int bc_length; /* For statistical purposes */

int full_ins_size(ilist i)
{
  int size = 1 + i->argsize;

  if (i->cvars)
    size += i->arg;
  if (i->cst)
    size += sizeof(value);

  return size;
}

instruction *ins_encode(instruction *codeins, ilist i)
{
  *codeins++ = i->ins;
  switch (i->argsize)
    {
    case 1: *codeins++ = i->arg; break;
    case 2: *codeins++ = i->arg >> 8; *codeins++ = i->arg; break;
    case 0: break;
    default: assert(0);
    }
  if (i->cvars)
    {
      memcpy(codeins, i->cvars, i->arg * sizeof *i->cvars);
      codeins += i->arg * sizeof *i->cvars;
    }
  if (i->cst)
    {
      GCCHECK(i->cst->lvalue);
      WINSCST(codeins, i->cst->lvalue);
      codeins += sizeof(value);
    }
  return codeins;
}

static ilist add_ins(instruction ins, u8 argsize, fncode fn)
{
  ilist newp = allocate(fnmemory(fn), sizeof *newp);

  *fn->last_ins = newp;
  newp->next = NULL;
  fn->last_ins = &newp->next;

  newp->ins = ins;
  newp->argsize = argsize;
  newp->to = NULL;
  newp->cvars = NULL;
  newp->cst = NULL;
  newp->lab = fn->next_label;
  if (fn->next_label) fn->next_label->ins = newp;
  fn->next_label = NULL;

  return newp;
}

void adjust_depth(int by, fncode fn)
/* Effects: Adjusts the current static stack depth of fn by the given
     amount. This is necessary for structures such as 'if' (which have
     code to compute 2 values, but which leave one on the stack).
   Modifies: fn
*/
{
  fn->current_depth += by;
  if (fn->current_depth > fn->max_depth) fn->max_depth = fn->current_depth;
}

fncode new_fncode(struct global_state *gstate, location l, int toplevel, i8 nargs)
/* Returns: A new function code structure (in which code for functions
     may be generated).
*/
{
  block_t afnmemory = new_block();
  fncode newp = allocate(afnmemory, sizeof *newp);

  newp->l = l;
  newp->toplevel = toplevel;
  newp->fnmemory = afnmemory;
  newp->instructions = NULL;
  newp->last_ins = &newp->instructions;
  newp->current_depth = newp->max_depth = 0;
  newp->loopcount = 0;
  newp->nargs = nargs;
  newp->next_label = NULL;
  newp->blks = NULL;
  PUSH_LIST(newp->cstpro);
  newp->cstpro.cl = &newp->csts;
  init_list(&newp->csts);
  newp->gstate = gstate;
  GCPRO1(newp->gstate);		/* Safe as new_fncode/delete_fncode called
				   in LIFO order */

  return newp;
}

void delete_fncode(fncode fn)
/* Effects: deletes fncode 'fn'
 */
{
  GCPOP(1);
  POP_LIST(fn->cstpro);
  free_block(fn->fnmemory);
}

block_t fnmemory(fncode fn)
/* Returns: fnmemory block for fn
 */
{
  return fn->fnmemory;
}

struct global_state *fnglobals(fncode fn)
/* Returns: global state for fn
 */
{
  return fn->gstate;
}

int fntoplevel(fncode fn)
/* Returns: true if 'fn' is the toplevel function
 */
{
  return fn->toplevel;
}

struct local_value *add_constant(value cst, fncode fn)
/* Effects: Adds a constant to code of 'fn'.
*/
{
  return addtail(fn->fnmemory, &fn->csts, cst);
}

void ins_constant(value cst, fncode fn)
/* Effects: Adds code to push cst onto the stack in 'fn'
   Modifies: fn
*/
{
  ins0(OPmcst, fn)->cst = add_constant(cst, fn);
}

u8 *ins_closure(value code, u16 clen, fncode fn)
/* Effects: Adds code for a 'clen' variable closure with function 'code'
     to 'fn'
   Returns: Pointer to area to add the closure variables
*/
{
  ilist cins = add_ins(OPmclosure, 1, fn);

  cins->arg = clen;
  cins->cst = add_constant(code, fn);
  cins->cvars = allocate(fnmemory(fn), clen * sizeof(*cins->cvars));
  adjust_depth(1, fn);

  return cins->cvars;
}

ilist ins0(instruction ins, fncode fn)
/* Effects: Adds instruction ins to code of 'fn'.
   Modifies: fn
*/
{
  switch (ins)
    {
    case OPmexec4 ... OPmexec4 + 15: 
      adjust_depth(-(ins - OPmexec4), fn);
      break;
    case OPmset:
      adjust_depth(-2, fn);
      break;
    case OPmpop: case OPmeq: case OPmne: case OPmref:
    case OPmlt: case OPmle: case OPmgt: case OPmge: case OPmadd: case OPmsub: 
    case OPmmultiply: case OPmdivide: case OPmremainder: case OPmbitand: 
    case OPmbitor: case OPmbitxor: case OPmshiftleft: case OPmshiftright:
      adjust_depth(-1, fn);
      break;
    case OPmcst: case OPmundefined: case OPmint3 ... OPmint3 + 7:
      adjust_depth(1, fn);
      break;
    case OPmreturn: case OPmnegate: case OPmbitnot: case OPmnot:
    case OPmscheck4 ... OPmscheck4 + 15:
      break;
    default:
      fprintf(stderr, "unknown instruction %d\n", ins);
      assert(0);
    }
  return add_ins(ins, 0, fn);
}

void insprim(instruction ins, int nargs, fncode fn)
/* Effects: Adds instruction ins to code of 'fn'.
   Modifies: fn
*/
{
  adjust_depth(-(nargs - 1), fn);
  add_ins(ins, 0, fn);
}

void ins1(instruction ins, int arg1, fncode fn)
/* Effects: Adds instruction ins to code of 'fn'.
     The instruction has one argument, arg1.
   Modifies: fn
*/
{
  switch (ins)
    {
    case OPmreadl: case OPmreadc: case OPmclosure:
      adjust_depth(1, fn);
      break;
    case OPmexitn: case OPmclearl: case OPmwritel: case OPmwritec:
    case OPmvcheck4 ... OPmvcheck4 + 15:
      /* Note: OPmexitn *MUST NOT* modify stack depth */
      break;
    default:
      assert(0);
    }
  add_ins(ins, 1, fn)->arg = arg1;
}

void ins2(instruction ins, int arg2, fncode fn)
/* Effects: Adds instruction ins to code of 'fn'.
     The instruction has a two byte argument (arg2), stored in big-endian
     format.
   Modifies: fn
*/
{
  switch (ins)
    {
    case OPmreadg:
      adjust_depth(1, fn);
      break;
    case OPmwriteg:
      break;
    case OPmexecg4 ... OPmexecg4 + 15: 
      adjust_depth(-(ins - OPmexecg4) + 1, fn);
      break;
    default:
      assert(0);
    }
  add_ins(ins, 2, fn)->arg = arg2;
}

void branch(instruction abranch, label to, fncode fn)
/* Effects: Adds a branch instruction to lavel 'to' to instruction 
     list 'next'.
     A 1 byte offset is added at this stage.
   Requires: 'branch' be a 1 byte branch instruction.
   Modifies: fn
*/
{
  /* We adjust stack depth even for "preserving" branches. It's up to the
     code using these to readjust the stack depth at the branch target
     (when setting the label) */
  switch (abranch)
    {
    case OPmba3: break;
    case OPmbt3: case OPmbtp3: case OPmbfp3: case OPmbf3:
      adjust_depth(-1, fn);
      break;
    default: assert(0);
    }
  /* assume a small offset by default */
  add_ins(abranch, 0, fn)->to = to;
}

static label real_label(label l)
{
  while (l->alias)
    l = l->alias;
  assert(l->ins);
  return l;
}

static void resolve_labels(fncode fn)
/* Effects: Removes all references in branches to labels that are aliases
     (replaces them with the 'real' label.
   Modifies: fn
*/
{
  ilist scan;

  for (scan = fn->instructions; scan; scan = scan->next)
    {
      if (scan->to)
	scan->to = real_label(scan->to);
    } 
}

static void number_instructions(fncode fn)
/* Effects: Numbers the instructions in fn (starting from the beginning)
   Modifies: fn
*/
{
  u32 offset;
  ilist scan;

  for (scan = fn->instructions, offset = 0; scan;
       offset += full_ins_size(scan), scan = scan->next)
    scan->offset = offset;
}

static int resolve_offsets(fncode fn)
/* Effects: Resolves all branch offsets in fn. Increases the size of
     the branches if necessary.
   Returns: TRUE if all branches could be resolved without increasing
     the size of any branches
*/
{
  ilist scan;
  int ok = TRUE;

  for (scan = fn->instructions; scan; scan = scan->next)
    {
      if (scan->to)		/* This is a branch */
	{
	  i32 offset = scan->to->ins->offset - scan->offset;
	  int size = scan->argsize;
	  instruction branchins;

	  switch (scan->ins)
	    {
	    case OPmbf3 ... OPmbf3 + 7: branchins = OPmbf3; break;
	    case OPmbfp3 ... OPmbfp3 + 7: branchins = OPmbfp3; break;
	    case OPmbt3 ... OPmbt3 + 7: branchins = OPmbt3; break;
	    case OPmbtp3 ... OPmbtp3 + 7: branchins = OPmbtp3; break;
	    case OPmba3 ... OPmba3 + 7: branchins = OPmba3; break;
	    default: assert(0); branchins = OPmba3; break;
	    }

	  if (size == 2)
	    {
	      /* Two byte branch */
	      offset -= 3;

	      if (offset >= INTEGER2_MIN && offset <= INTEGER2_MAX)
		{
		  scan->ins = branchins + 7; /* he he */
		  scan->arg = offset;
		}
	      else
		/* Branch doesn't fit. TBD. */
		log_error(fn->l, "function too big");
	    }
	  else if (size == 1)
	    {
	      /* One byte */
	      offset -= 2;

	      if (offset >= INTEGER1_MIN && offset <= INTEGER1_MAX)
		{
		  scan->ins = branchins; /* he he */
		  scan->arg = offset;
		}
	      else
		{
		  /* Make a 2 byte branch */
		  scan->argsize = 2;
		  ok = FALSE;
		}
	    }
	  else /* size == 0 */
	    {
	      /* 0 bytes (offset from 1-6) */
	      offset -= 1;

	      if (offset >= 1 && offset <= 6)
		scan->ins = branchins + offset;
	      else
		{
		  /* Make a 1 byte branch */
		  scan->argsize = 1;
		  ok = FALSE;
		}
	    }
	}
    }
  return ok;
}

static ilist ins_skip(ilist i, int count)
{
  while (count--)
    i = i->next;
  return i;
}

static void delete_ins(ilist i)
{
  label ilab = i->lab;

  *i = *i->next;
  if (i->lab)
    {
      i->lab->ins = i;
      if (ilab)
	{
	  assert(!ilab->alias);
	  assert(!i->lab->alias);
	  ilab->alias = i->lab;
	  ilab->ins = NULL;
	  i->label_used = TRUE; /* conservatively assume the label is used */
	}
    }
  else if (ilab)
    {
      i->lab = ilab;
      i->label_used = TRUE; /* conservatively assume the label is used */
    }
}

typedef struct {
  bool read, dead;
  u8 new_index;
} varinfo;

static instruction class_write[] = { OPmwritel, OPmwritec, OPmwriteg };
static instruction class_writed[] = { OPmwritedl, OPmwritedc, OPmwritedg };
static instruction class_read[] = { OPmreadl, OPmreadc, OPmreadg };

static bool is_varop(instruction *byclass, ilist i,
		     variable_class *class, u16 *offset)
{
  int c;

  *offset = i->arg;
  for (c = local_var; c <= global_var; c++)
    if (i->ins == byclass[c])
      {
	*class = c;
	return TRUE;
      }
  return FALSE;
}

static bool is_read(ilist i, variable_class *class, u16 *offset)
{
  return is_varop(class_read, i, class, offset);
}

static bool is_write(ilist i, variable_class *class, u16 *offset)
{
  return is_varop(class_write, i, class, offset);
}

static bool is_writed(ilist i, variable_class *class, u16 *offset)
{
  return is_varop(class_writed, i, class, offset);
}

static bool simpleopt(fncode fn, varinfo *vars, u8 nb_locals)
/* Effects: Do simple peephole optimisations on fn. Currently:
     - remove unreachable code after ba3, return
     - remove branch to next ins
     - replace ba to return w/ return
     - replace branch to ba with 2nd branch's dest
     - replace write+discard with write-discard ins
     - replace writed+read with write
     - drop cst+discard, read+discard
     - drop variables which are never read
   Modifies: fn
 */
{
  ilist scan;
  bool reachable = TRUE, change = FALSE, delete_last = FALSE;
  u8 i;

  for (i = 0; i < fn->nargs; i++)
    vars[i].read = TRUE;
  for (; i < nb_locals; i++)
    vars[i].read = FALSE;

  for (scan = fn->instructions; scan; scan = scan->next)
    scan->label_used = FALSE;

  for (scan = fn->instructions; scan; )
    {
      instruction ins = scan->ins;
      variable_class vclass;
      u16 voffset;

      if (!reachable && !scan->lab)
	{
	  change = TRUE;
	  if (!scan->next)
	    {
	      /* Hack for last instruction */
	      delete_last = TRUE;
	      break;
	    }
	  delete_ins(scan);
	  continue;
	}
      reachable = TRUE;

      if (is_write(scan, &vclass, &voffset))
	{
	  ilist next = scan->next;

	  /* replace write+pop w/ writed as long as the pop has no label */
	  if (next && next->ins == OPmpop && !next->lab)
	    {
	      change = TRUE;
	      delete_ins(next);
	      scan->ins = class_writed[vclass];
	    }
	  /* Remove write of dead local */
	  else if (vclass == local_var && vars[voffset].dead)
	    {
	      change = TRUE;
	      delete_ins(scan);
	      continue;
	    }
	}
      else if (is_writed(scan, &vclass, &voffset))
	{
	  ilist next = scan->next;
	  variable_class vrclass;
	  u16 vroffset;

	  /* replace writed+recall (of same var) w/ write as long as the
	     read has no label */
	  if (next && !next->lab && is_read(next, &vrclass, &vroffset) &&
	      vrclass == vclass && vroffset == voffset)
	    {
	      change = TRUE;
	      delete_ins(next);
	      scan->ins = class_write[vclass];
	    }
	  /* Replace writed by pop for dead local */
	  else if (vclass == local_var && vars[voffset].dead)
	    {
	      change = TRUE;
	      scan->ins = OPmpop;
	      scan->argsize = 0;
	    }
	}
      /* Remove clear of dead local */
      else if (ins == OPmclearl && vars[scan->arg].dead)
	{
	  change = TRUE;
	  delete_ins(scan);
	  continue;
	}
      else if (ins == OPmclosure)
	{
	  /* Closure vars are assumed read */
	  for (i = 0; i < scan->arg; i++)
	    {
	      u8 cvar = scan->cvars[i];

	      if ((cvar & 1) == local_var)
		vars[cvar >> 1].read = TRUE;
	    }
	}
      else if (ins == OPmcst || is_read(scan, &vclass, &voffset))
	{
	  ilist next = scan->next;

	  /* drop read|cst/pop as long as the pop has no label */
	  if (next && next->ins == OPmpop && !next->lab)
	    {
	      change = TRUE;
	      delete_ins(scan);
	      delete_ins(scan);
	      continue;
	    }
	  else if (ins != OPmcst && vclass == local_var)
	    vars[voffset].read = TRUE;
	}
      else if (ins == OPmba3)
	{
	  ilist dest = real_label(scan->to)->ins;

	  /* branch to next instruction, just remove */
	  if (dest == scan->next)
	    {
	      change = TRUE;
	      delete_ins(scan);
	      continue;
	    }
	  /* replace branch to return by return */
	  else if (dest->ins == OPmreturn)
	    {
	      ins = scan->ins = OPmreturn;
	      scan->to = NULL;
	      scan->argsize = 0;
	    }
	  else
	    reachable = FALSE;
	}
      if (ins == OPmreturn)
	reachable = FALSE;

      /* Notice which labels are really used, short-circuit branch to ba */
      if (ins == OPmba3 || ins == OPmbt3 || ins == OPmbtp3 || 
	  ins == OPmbf3 || ins == OPmbfp3)
	{
	  ilist dest = real_label(scan->to)->ins;

	  if (dest->ins == OPmba3)
	    scan->to = dest->to;
	  real_label(scan->to)->ins->label_used = TRUE;
	}

      scan = scan->next;
    }

  /* Notice dead locals */
  for (i = 0; i < nb_locals; i++)
    if (!vars[i].read && !vars[i].dead)
      {
	change = TRUE;
	vars[i].dead = TRUE;
      }

  /* Remove unused labels. Also does in last instruction if need be. */
  for (scan = fn->instructions; scan; scan = scan->next)
    {
      if (!scan->label_used && scan->lab)
	{
	  change = TRUE;
	  scan->lab = NULL;
	}
      /* Hack */
      if (delete_last && !scan->next->next)
	scan->next = NULL;
    }


  return change;
}

static void remap_vars(fncode fn, varinfo *vars, u8 *nb_locals)
/* Effects: remaps local var indices of fn to take account of dead
     vars
*/
{
  u8 i, voffset;
  ilist scan;

  for (i = voffset = 0; i < *nb_locals; i++)
    if (!vars[i].dead)
      vars[i].new_index = voffset++;
  *nb_locals = voffset;

  for (scan = fn->instructions; scan; scan = scan->next)
    switch (scan->ins)
      {
      case OPmwritel: case OPmwritedl: case OPmreadl: case OPmclearl:
	scan->arg = vars[scan->arg].new_index;
	break;
      case OPmclosure:
	for (i = 0; i < scan->arg; i++)
	  {
	    u8 cvar = scan->cvars[i];

	    if ((cvar & 1) == local_var)
	      scan->cvars[i] = vars[cvar >> 1].new_index << 1 | local_var;
	  }
	break;
      }
}

static bool threebit(ilist scan)
{
  return scan->arg < 8;
}

static void use_compact_instructions(fncode fn)
/* Effects: Replaces instructions in fn with equivalent compact 
     encodings if possible
     (done after opt to avoid dealing with these at that point)
*/
{
  ilist scan;

  for (scan = fn->instructions; scan; scan = scan->next)
    switch (scan->ins)
      {
      case OPmcst:
	{
	  value cst = scan->cst->lvalue;

	  GCCHECK(cst);
	  if (INTEGERP(cst))
	    {
	      long i = intval(cst);

	      if (i >= 0 && i <= 7)
		{
		  scan->ins = OPmint3 + i;
		  scan->cst = NULL;
		}
	      else if (i == 42) /* undefined */
		{
		  scan->ins = OPmundefined;
		  scan->cst = NULL;
		}
	    }
	  break;
	}
      case OPmwritel:
	if (threebit(scan))
	  {
	    scan->ins = OPmwritel3 + scan->arg;
	    scan->argsize = 0;
	  }
	break;
      case OPmwritedl:
	if (threebit(scan))
	  {
	    scan->ins = OPmwritedl3 + scan->arg;
	    scan->argsize = 0;
	  }
	break;
      case OPmreadl:
	if (threebit(scan))
	  {
	    scan->ins = OPmreadl3 + scan->arg;
	    scan->argsize = 0;
	  }
	break;
      case OPmreadc:
	if (threebit(scan))
	  {
	    scan->ins = OPmreadc3 + scan->arg;
	    scan->argsize = 0;
	  }
	break;
      }
}

void peephole(fncode fn, u8 *nb_locals)
/* Effects: Does some peephole optimisation on instructions of 'fn'
     Currently this only includes branch size optimisation (1 vs 2 bytes)
     and removal of unconditional branches to the next instruction.
     Also resolves branches...
   Modifies: fn
   Requires: All labels be defined
*/
{
  varinfo *vars = allocate(fnmemory(fn), *nb_locals * sizeof *vars);

  if (debug_lvl < 3)
    {
      memset(vars, 0, *nb_locals * sizeof *vars);
      while (simpleopt(fn, vars, *nb_locals))
	;
      remap_vars(fn, vars, nb_locals);
    }
  use_compact_instructions(fn);

  resolve_labels(fn);
  do number_instructions(fn);
  while (!resolve_offsets(fn));
}

struct code *generate_fncode(fncode fn, u8 nb_locals,
			     struct string *help,
			     struct string *varname,
			     struct string *afilename,
			     int alineno)
/* Returns: A code structure with the instructions and constants in 'fn'.
   Requires: generate_fncode may only be called on the result of the most
     recent call to new_fncode. That call is then deemed to never have
     occured :-) (this means that new_fncode/generate_fncode must be paired
     in reverse temporal order)
*/
{
  u16 sequence_length, offset;
  ilist scanins;
  instruction *codeins;
  struct local_value *scancst;
  struct code *gencode;
  uvalue size;

  peephole(fn, &nb_locals);

  /* Count # of instructions */
  sequence_length = 0;
  for (scanins = fn->instructions; scanins; scanins = scanins->next)
    sequence_length += full_ins_size(scanins);

  GCPRO2(help, varname); GCPRO1(afilename);
  size = offsetof(struct code, ins) + sequence_length * sizeof(instruction);
  bc_length += size;
  gencode = gc_allocate(size);
  GCPOP(3);

  gencode->o.size = size;
  gencode->o.forwarded = FALSE;
  gencode->o.type = itype_code;
  SETFLAGS(gencode->o, OBJ_IMMUTABLE); /* Code is immutable */
  gencode->nb_locals = nb_locals;
  gencode->stkdepth = fn->max_depth;
  gencode->nargs = fn->nargs;
  gencode->help = help;
  gencode->lineno = alineno;
  gencode->filename = afilename;
  gencode->varname = varname;

  gencode->call_count = gencode->instruction_count = 0;

  /* Encode the instructions */
  codeins = gencode->ins;
  for (scanins = fn->instructions; scanins; scanins = scanins->next)
    codeins = ins_encode(codeins, scanins);

#ifdef GCSTATS
  gcstats.anb[itype_code]++;
  gcstats.asizes[itype_code] += size;
#endif

  return gencode;
}

label new_label(fncode fn)
/* Returns: A new label which points to nothing. Use label() to make it
     point at a particular instruction.
*/
{
  label newp = allocate(fn->fnmemory, sizeof *newp);

  newp->ins = NULL;
  newp->alias = NULL;

  return newp;
}

void set_label(label lab, fncode fn)
/* Effects: lab will point at the next instruction generated with ins0, 
     ins1, ins2 or branch.
   Modifies: lab
*/
{
  if (fn->next_label) lab->alias = fn->next_label;
  else fn->next_label = lab;
}

void start_block(const char *name, bool mcontinue, bool discard, fncode fn)
/* Effects: Starts a block called name (may be NULL), which can be
     exited with exit_block()
*/
{
  blocks newp = allocate(fn->fnmemory, sizeof *newp);

  newp->next = fn->blks;
  newp->name = name;
  newp->exitlab = new_label(fn);
  newp->mcontinue = mcontinue;
  newp->discard = discard;
  newp->stack_depth = fn->current_depth;

  fn->blks = newp;
}

void end_block(fncode fn)
/* Effects: End of named block. Generate exit label
*/
{
  set_label(fn->blks->exitlab, fn);
  fn->blks = fn->blks->next;
}

label exit_block(const char *name, bool mcontinue, bool *discard, fncode fn)
/* Effects: Generates code to pop stack in preparation for exiting
     from specified named block
     mcontinue is a flag to distinguish blocks for continue from blocks
     for break. exit_block will only match a block with matching mcontinue flag
     *discard is set to TRUE if the block's result is ignored (no result should
     be placed on stack)
   Returns: the target label to jump to, NULL if the named block doesn't exist
*/
{
  blocks find = fn->blks;
  int npop;

  for (;;)
    {
      if (!find) return NULL;
      if (find->mcontinue == mcontinue)
	{
	  if (find->name == NULL && name == NULL)
	    break;
	  else if (find->name != NULL && name != NULL &&
		   stricmp(name, find->name) == 0)
	    break;
	}
      find = find->next;
    }

  npop = fn->current_depth - find->stack_depth;
  assert(npop >= 0);
  if (npop > 1)
    ins1(OPmexitn, npop, fn);
  else if (npop == 1)
    {
      ins0(OPmpop, fn);
      /* We shouldn't modify the stack depth here! So undo pop effects */
      adjust_depth(1, fn);
    }

  *discard = find->discard;

  return find->exitlab;

}

void enter_loop(fncode fn)
/* Effects: Note that we are entering a loop 
 */
{
  fn->loopcount++;
}

void exit_loop(fncode fn)
/* Effects: Note that we are exiting a loop 
 */
{
  fn->loopcount--;
}

bool in_loop(fncode fn)
/* Returns: TRUE if we are in a loop
 */
{
  return fn->loopcount > 0;
}

