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

#include <string.h>
#include <stdlib.h>
#include <stddef.h>
#include "mudlle.h"
#include "interpret.h"
#include "alloc.h"
#include "types.h"
#include "code.h"
#include "global.h"
#include "error.h"
#include "call.h"
#include "runtime/runtime.h"
#include "runtime/stringops.h"
#include "runtime/symbol.h"
#include "table.h"

#ifndef TINY
/* As good a place as any other */
const char *COPYRIGHT = "\
Copyright (c) 1993-1999 David Gay and Gustav Hållberg\n\
All rights reserved.\n\
\n\
Permission to use, copy, modify, and distribute this software for any\n\
purpose, without fee, and without written agreement is hereby granted,\n\
provided that the above copyright notice and the following two paragraphs\n\
appear in all copies of this software.\n\
\n\
IN NO EVENT SHALL DAVID GAY OR GUSTAV HALLBERG BE LIABLE TO ANY PARTY FOR\n\
DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT\n\
OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF DAVID GAY OR\n\
GUSTAV HALLBERG HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n\
\n\
DAVID GAY AND GUSTAV HALLBERG SPECIFICALLY DISCLAIM ANY WARRANTIES,\n\
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND\n\
FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN\n\
\"AS IS\" BASIS, AND DAVID GAY AND GUSTAV HALLBERG HAVE NO OBLIGATION TO\n\
PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.\n\
";
#endif

/* Macros for fast access to the GC'ed stack & code structures.
   RESTORE_INS must be called after anything that may have caused a GC
*/

#define RESTORE_SP() (stkpos = (value *)sp)
#define SAVE_SP() (sp = (u8 *)stkpos)

#define FAST_RESERVE(n) (stkpos - (n) < (value *)splimit ? (SAVE_SP(), SAVE_INS(), stack_reserve((n) * sizeof(value)), RESTORE_INS()) : 0)
#define FAST_POP() (*stkpos++)
#define FAST_POPN(n) ((void)(stkpos += (n)))
#define FAST_PUSH(v) do { *--stkpos = (v); } while(0)
#define FAST_GET(n) (stkpos[(n)])
#define FAST_SET(n, v) (stkpos[(n)] = (v))

#define RESTORE_INS() (ins = &frame->fn->code->ins[frame->ins])
#define SAVE_INS() (frame->ins = ins - frame->fn->code->ins)

#define INSU8() (*ins++)
#define INSI8() ((i8)INSU8())
#define INSU16() (byte1 = *ins++, (byte1 << 8) + *ins++)
#define INSI16() ((i16)INSU16())
#define INSSKIP(n) (ins += (n))

#define INSCST() (ins += sizeof(value), RINSCST(ins - sizeof(value)))

struct interpret_frame {
  struct generic_frame g;
  u16 ins;
#ifndef TINY
  u32 start_ins;
#endif
  struct closure *fn;
  struct variable *locals[1/*n*/];
};

static uint8_t isizes[256];

static void set_branch_size(uint8_t bop)
{
  uint8_t i;

  isizes[bop + 0] = 2;
  for (i = 1; i <= 6; i++)
    isizes[bop + i] = 1;
  isizes[bop + 7] = 3;
}

void interpret_init(void)
{
  u8 i;

  isizes[OPmbitand] = 1;
  isizes[OPmne] = 1;
  isizes[OPmge] = 1;
  isizes[OPmbitor] = 1;
  isizes[OPmshiftleft] = 1;
  isizes[OPmsub] = 1;
  isizes[OPmeq] = 1;
  isizes[OPmdivide] = 1;
  isizes[OPmadd] = 1;
  isizes[OPmgt] = 1;
  isizes[OPmlt] = 1;
  isizes[OPmshiftright] = 1;
  isizes[OPmbitnot] = 1;
  isizes[OPmle] = 1;
  isizes[OPmnot] = 1;
  isizes[OPmbitxor] = 1;
  isizes[OPmmultiply] = 1;
  isizes[OPmremainder] = 1;
  isizes[OPmnegate] = 1;
  isizes[OPmref] = 1;
  isizes[OPmset] = 1;

  set_branch_size(OPmbf3);
  set_branch_size(OPmbt3);
  set_branch_size(OPmba3);

  isizes[OPmreadg] = 3;
  isizes[OPmwriteg] = 3;
  isizes[OPmwritedg] = 3;
  isizes[OPmreadc] = 2;
  isizes[OPmwritec] = 2;
  isizes[OPmwritedc] = 2;
  isizes[OPmreadl] = 2;
  isizes[OPmwritel] = 2;
  isizes[OPmwritedl] = 2;
  for (i = OPmreadl3; i <= OPmreadl3 + 7; i++)
    isizes[i] = 1;
  for (i = OPmreadc3; i <= OPmreadc3 + 7; i++)
    isizes[i] = 1;
  for (i = OPmwritel3; i <= OPmwritel3 + 7; i++)
    isizes[i] = 1;
  for (i = OPmwritedl3; i <= OPmwritedl3 + 7; i++)
    isizes[i] = 1;

  for (i = OPmint3; i <= OPmint3 + 7; i++)
    isizes[i] = 1;
  for (i = OPmexec4; i <= OPmexec4 + 15; i++)
    isizes[i] = 1;
  for (i = OPmexecg4; i <= OPmexecg4 + 15; i++)
    isizes[i] = 3;
  for (i = OPmexecprim6; i <= OPmexecprim6 + 63; i++)
    isizes[i] = 1;
  isizes[OPmexitn] = 2;
  for (i = OPmvcheck4; i <= OPmvcheck4 + 15; i++)
    isizes[i] = 2;
  for (i = OPmscheck4; i <= OPmscheck4 + 15; i++)
    isizes[i] = 1;
  isizes[OPmpop] = 1;
  isizes[OPmcst] = 1 + sizeof(value);
  isizes[OPmundefined] = 1;
  isizes[OPmclearl] = 2;
  isizes[OPmclosure] = 0; // special
  isizes[OPmreturn] = 1;
}

u8 ins_size(instruction i)
/* Requires: i != OPmclosure */
{
  assert(isizes[i] > 0);

  return isizes[i];
}

#ifndef TINY
#include "print.h"

static u32 instruction_number;
static i8 actual_args = -1;

static void print_bytecode(struct interpret_frame *frame)
{
  struct closure *fn = frame->fn;

  if (fn->code->filename->str[0])
    {
      i8 i, nargs;
      uvalue first_arg_offset;
      bool first = TRUE;

      print_fnname(muderr, fn);
      mputs("(", muderr);
      first_arg_offset = frame->fn->code->nb_locals - 1;
      nargs = frame->fn->code->nargs;

      /* Evil hack part 2 (see push_closure for part 1) */
      if (actual_args >= 0)
	{
	  first_arg_offset += actual_args - nargs;
	  nargs = actual_args;
	}

      if (nargs < 0)
	nargs = 1; /* varargs case */

      for (i = 0; i < nargs; i++)
	{
	  value arg;

	  if (!first)
	    mputs(", ", muderr);
	  first = FALSE;

	  arg = frame->locals[first_arg_offset - i];
	  if (TYPE(arg, itype_variable))
	    arg = ((struct variable *)arg)->vvalue;
	  mprint(muderr, prt_print, arg);
	}
      mputs(")" EOL, muderr);
    }
  /* Only meaningful in the first frame */
  actual_args = -1;
}
#endif

static value code_ref(value x1, value x2)
{
  if (!POINTERP(x1))
    RUNTIME_ERROR(error_bad_type);
  switch (OBJTYPE(x1))
    {
    case type_vector: {
      struct vector *vec = x1;
      ivalue idx;

      ISINT(x2);
      idx = intval(x2);
      if (idx < 0 || idx >= vector_len(vec))
	RUNTIME_ERROR(error_bad_index);
      return (vec->data[idx]);
    }
#ifndef TINY
    case type_string:
      return code_string_ref(x1, x2);
    case type_table: {
      struct symbol *sym;
      struct string *s = x2;

      TYPEIS(s, type_string);
      if (!table_lookup(x1, s->str, &sym)) return NULL;
      return sym->data;
    }
#endif
    default: RUNTIME_ERROR(error_bad_type);
    }
}

static value code_set(value x1, value x2, value x3)
{
  if (!POINTERP(x1))
    RUNTIME_ERROR(error_bad_type);
  switch (OBJTYPE(x1))
    {
    case type_vector: {
      struct vector *vec = x1;
      ivalue idx;

      if (readonlyp(vec))
	RUNTIME_ERROR(error_value_read_only);
      ISINT(x2);
      idx = intval(x2);

      if (idx < 0 || idx >= vector_len(vec))
	RUNTIME_ERROR(error_bad_index);
      vec->data[idx] = x3;
      return x3;
    }
#ifndef TINY
    case type_string:
      return code_string_set(x1, x2, x3);
    case type_table:
      return table_mset(x1, x2, x3);
#endif
    default: RUNTIME_ERROR(error_bad_type);
    }
}

static CC execute_bytecode(struct interpret_frame *frame)
{
  instruction *ins, byteop;
  u16 coffset;
  u8 byte1;
  value *stkpos;
  value arg1, arg2, result;
  struct obj *called;
  struct primitive_ext *op;
  u8 nargs;
  uint8_t dobranch;

  RESTORE_SP();
  RESTORE_INS();

 nextins:
#ifndef TINY
  instruction_number++;
#endif
  MDBG8(dbg_ins); MDBG16(ins);
  byteop = INSU8();
  MDBG8(byteop); MDBG16(stkpos);

  switch (byteop)
    {
    case OPmlt: case OPmle: case OPmgt: case OPmge: case OPmadd: case OPmsub: 
    case OPmmultiply: case OPmdivide: case OPmremainder: case OPmbitand: 
    case OPmbitor: case OPmbitxor: case OPmshiftleft: case OPmshiftright:
    {
      ivalue i1, i2;

      arg2 = FAST_POP();
      arg1 = FAST_GET(0);
      if (!(INTEGERP(arg1) && INTEGERP(arg2)))
	runtime_error(error_bad_type); 
      i1 = intval(arg1); i2 = intval(arg2);
      switch (byteop)
	{
	default:
	  assert(0);
	  result = NULL;
	  break;
	case OPmlt:
	  result = makebool((ivalue)arg1 < (ivalue)arg2);
	  break;
	case OPmle:
	  result = makebool((ivalue)arg1 <= (ivalue)arg2);
	  break;
	case OPmgt:
	  result = makebool((ivalue)arg1 > (ivalue)arg2);
	  break;
	case OPmge:
	  result = makebool((ivalue)arg1 >= (ivalue)arg2);
	  break;

	case OPmadd:
	  result = (value)((ivalue)arg1 + (ivalue)arg2 - 1);
	  break;
	case OPmsub:
	  result = (value)((ivalue)arg1 - (ivalue)arg2 + 1);
	  break;
	case OPmmultiply:
	  result = (makeint(intval(arg1) * intval(arg2)));
	  break;
	case OPmdivide:
	case OPmremainder:
	  if (i2 == 0)
	    runtime_error(error_divide_by_zero);
	  result = makeint(byteop == OPmdivide ? i1 / i2 : i1 % i2);
	  break;

	case OPmbitand:
	  result = (value)((ivalue)arg1 & (ivalue)arg2);
	  break;
	case OPmbitor:
	  result = (value)((ivalue)arg1 | (ivalue)arg2);
	  break;
	case OPmbitxor:
	  result = (value)((ivalue)arg1 ^ (ivalue)arg2 | 1);
	  break;

	case OPmshiftleft:
	  result = makeint(intval(arg1) << intval(arg2));
	  break;
	case OPmshiftright:
	  result = makeint(intval(arg1) >> intval(arg2));
	  break;
	}
      FAST_SET(0, result);
      break;
    }
    case OPmreturn: 
#ifndef TINY
      /* Profiling */
      frame->fn->code->instruction_count += instruction_number - frame->start_ins;
#endif
      result = FAST_GET(0);
      SAVE_SP();
      FA_POP(&fp, &sp);
      stack_push(result);
      return;
    case OPmcst:
      FAST_RESERVE(1);
      FAST_PUSH(INSCST());
      GCCHECK(FAST_GET(0));
      break;

    case OPmint3 ... OPmint3 + 7:
      FAST_RESERVE(1);
      FAST_PUSH(makeint(byteop - OPmint3));
      GCCHECK(FAST_GET(0));
      break;

    case OPmundefined:
      FAST_RESERVE(1);
      FAST_PUSH(makeint(42));
      GCCHECK(FAST_GET(0));
      break;

    case OPmclosure:
      {
	u8 nvars = INSU8(), var;
	struct closure *new_closure;

	SAVE_SP(); SAVE_INS();
	new_closure = unsafe_alloc_and_push_closure(nvars);
	RESTORE_INS(); RESTORE_SP();

	for (var = 0; var < nvars; var++)
	  {
	    u8 varspec = INSU8();
	    u8 whichvar = varspec >> 1;
	    struct variable *v;

	    if ((varspec & 1) == local_var)
	      v = frame->locals[frame->fn->code->nb_locals - 1 - whichvar];
	    else
	      v = frame->fn->variables[whichvar];

	    new_closure->variables[var] = v;
	  }
	new_closure->code = INSCST();
	break;
      }

    case OPmexec4 ... OPmexec4 + 15:
      called = FAST_POP();
      nargs = byteop - OPmexec4;

    execute_fn:
      {
	int err;

#if 0
	MDBG8(dbg_exec); MDBG8(nargs); MDBG16(called);
#endif
	SAVE_SP(); SAVE_INS();
	setup_call_stack(called, nargs);
	return;
      }

    case OPmexecg4 ... OPmexecg4 + 15:
      called = GVAR(globals, INSU16());
      nargs = byteop - OPmexecg4;
      goto execute_fn;

    case OPmexecprim6 ... OPmexecprim6 + 63: {
      called = PRIMITIVE_NB_TO_ATOM(byteop - OPmexecprim6);
      nargs = PRIMARGS(called);
      goto execute_fn;
    }
    case OPmpop:
      FAST_POPN(1);
      break;
    case OPmexitn:
      {
	u8 i = INSU8();
	FAST_POPN(i);
	break;
      }
    case OPmbf3 ... OPmbf3 + 7:
      byteop -= OPmbf3;
      dobranch = !istrue(FAST_POP());
      goto branch;
    case OPmbt3 ... OPmbt3 + 7:
      byteop -= OPmbt3;
      dobranch = istrue(FAST_POP());
      goto branch;

    case OPmba3 ... OPmba3 + 7:
      byteop -= OPmba3;
      dobranch = TRUE;

    branch:
    {
      i16 offset;

      if (byteop == 0)
	offset = INSI8();
      else if (byteop == 7)
	offset = INSI16();
      else
	offset = byteop;
      if (dobranch)
	{
	  INSSKIP(offset);
	  /* We exit the interpreter on backwards branches to ensure that
	     external conditions are noticed */
	  if (offset < 0)
	    {
	      SAVE_SP(); SAVE_INS();
	      return;
	    }
	}
      break;
    }


#define LOCAL frame->locals[frame->fn->code->nb_locals - 1 - INSU8()]
#define CLOSURE frame->fn->variables[INSU8()]
#define LOCAL3(x) frame->locals[frame->fn->code->nb_locals - 1 - (byteop - (x))]
#define CLOSURE3(x) frame->fn->variables[byteop - (x)]

#define RECALL(access) FAST_RESERVE(1); FAST_PUSH(access->vvalue)
#define ASSIGN(access) { (access)->vvalue = FAST_GET(0); }
#define ASSIGND(access) { (access)->vvalue = FAST_POP(); }

    case OPmclearl: ((struct variable *)LOCAL)->vvalue = NULL; break;
    case OPmreadl: RECALL(LOCAL); break;
    case OPmreadl3 ... OPmreadl3 + 7: RECALL(LOCAL3(OPmreadl3)); break;
    case OPmreadc: RECALL(CLOSURE); break;
    case OPmreadc3 ... OPmreadc3 + 7: RECALL(CLOSURE3(OPmreadc3)); break;
    case OPmreadg: FAST_RESERVE(1); FAST_PUSH(GVAR(globals, INSU16())); break;
    case OPmwritel: ASSIGN(LOCAL); break;
    case OPmwritel3 ... OPmwritel3 + 7: ASSIGN(LOCAL3(OPmwritel3)); break;
    case OPmwritec: ASSIGN(CLOSURE); break;
    case OPmwriteg: 
      {
	u16 goffset = INSU16();

#ifdef TINY
	if (GCONSTANT(globals, goffset))
	  runtime_error(error_variable_read_only);
	else
#endif
	  GVAR(globals, goffset) = FAST_GET(0);
	break;
      }

    case OPmwritedl: ASSIGND(LOCAL); break;
    case OPmwritedl3 ... OPmwritedl3 + 7: ASSIGND(LOCAL3(OPmwritedl3)); break;
    case OPmwritedc: ASSIGND(CLOSURE); break;
    case OPmwritedg: 
      {
	u16 goffset = INSU16();

#ifdef TINY
	if (GCONSTANT(globals, goffset))
	  runtime_error(error_variable_read_only);
	else
#endif
	  GVAR(globals, goffset) = FAST_POP();
	break;
      }

    case OPmeq:
      arg1 = FAST_POP();
      FAST_SET(0, makebool(FAST_GET(0) == arg1));
      break;
    case OPmne:
      arg1 = FAST_POP();
      FAST_SET(0, makebool(FAST_GET(0) != arg1));
      break;

    case OPmnegate:
      arg1 = FAST_GET(0);
      if (!INTEGERP(arg1))
	runtime_error(error_bad_type);
      FAST_SET(0, (value)(2 - (ivalue)arg1));
      break;

    case OPmbitnot:
      arg1 = FAST_GET(0);
      if (!INTEGERP(arg1))
	runtime_error(error_bad_type);
      FAST_SET(0, (value)(~(uvalue)arg1 | 1));
      break;

    case OPmnot:
      FAST_SET(0, makebool(!istrue(FAST_GET(0))));
      break;

      /* The type checks */
    case OPmvcheck4 + type_integer:
      arg1 = LOCAL->vvalue;
      if (!INTEGERP(arg1))
	runtime_error(error_bad_type);
      break;

    case OPmvcheck4 + type_string:
    case OPmvcheck4 + type_vector:
    case OPmvcheck4 + type_pair:
    case OPmvcheck4 + type_symbol:
    case OPmvcheck4 + type_table:
    case OPmvcheck4 + type_function:
    case OPmvcheck4 + type_null:
      arg1 = LOCAL->vvalue;
      if (!TYPE(arg1, byteop - OPmvcheck4))
	runtime_error(error_bad_type);
      break;

    case OPmvcheck4 + stype_none:
      INSU8();
      runtime_error(error_bad_type);

    case OPmvcheck4 + stype_list:
      arg1 = LOCAL->vvalue;
      if (!TYPE(arg1, type_null) && !TYPE(arg1, type_pair))
	runtime_error(error_bad_type);
      break;

    case OPmscheck4 + type_integer:
      arg1 = FAST_GET(0);
      if (!INTEGERP(arg1))
	runtime_error(error_bad_type);
      break;

    case OPmscheck4 + type_string:
    case OPmscheck4 + type_vector:
    case OPmscheck4 + type_pair:
    case OPmscheck4 + type_symbol:
    case OPmscheck4 + type_table:
    case OPmscheck4 + type_function:
    case OPmscheck4 + type_null:
      arg1 = FAST_GET(0);
      if (!TYPE(arg1, byteop - OPmscheck4))
	runtime_error(error_bad_type);
      break;

    case OPmscheck4 + stype_none:
      INSU8();
      runtime_error(error_bad_type);

    case OPmscheck4 + stype_list:
      arg1 = FAST_GET(0);
      if (!TYPE(arg1, type_null) && !TYPE(arg1, type_pair))
	runtime_error(error_bad_type);
      break;

    case OPmref:
      arg2 = FAST_POP();
#ifndef TINY
      SAVE_SP(); SAVE_INS();
#endif
      arg1 = code_ref(FAST_GET(0), arg2);
      if (arg1 == PRIMITIVE_STOLE_CC)
	arg1 = NULL;
      GCCHECK(arg1);
#ifndef TINY
      RESTORE_INS();
#endif
      FAST_SET(0, arg1);
      break;

    case OPmset:
      arg2 = FAST_POP();
      arg1 = FAST_POP();
#ifndef TINY
      SAVE_SP(); SAVE_INS();
#endif
      arg1 = code_set(FAST_GET(0), arg1, arg2);
      if (arg1 == PRIMITIVE_STOLE_CC)
	arg1 = NULL;
      GCCHECK(arg1);
#ifndef TINY
      RESTORE_INS();
#endif
      FAST_SET(0, arg1);
      break;

    default: assert(0);
    }
  goto nextins;
  /*SAVE_SP(); SAVE_INS(); */
}

static CC interpret_action2(frameact action, u8 **ffp, u8 **fsp)
{
  u8 *lfp = *ffp;
  struct interpret_frame *frame = (struct interpret_frame *)lfp;
  /* Note: this is safe because while frame->fn may have been forwarded
     already, the original object is still present unchanged (except for
     the forwarding info) at it's original location. We do want to
     read this before the forwarding of frame->fn, though. */
  u8 nb_locals = frame->fn->code->nb_locals;

  switch (action)
    {
    case fa_print:
#ifndef TINY
      print_bytecode(frame);
#endif
      break;
    case fa_gcforward: 
      {
	value *values, *last;

	forward((value *)&frame->fn);

	/* Forward stack */
	values = (value *)*fsp;
	last = (value *)lfp;
	while (values < last)
	  forward(values++);
	
	/* Forward locals */
	values = (value *)frame->locals;
	last = values + nb_locals;
	while (values < last)
	  forward(values++);
      }
      /* fall through */
    case fa_unwind: case fa_pop:
      pop_frame(ffp, fsp, offsetof(struct interpret_frame, locals) +
		nb_locals * sizeof(value));
      MDBG8(0xe5); MDBG16(sp);
      break;
    default: abort();
    }
}

static CC interpret_action(frameact action, u8 **ffp, u8 **fsp)
{
  if (action == fa_execute)
    execute_bytecode((struct interpret_frame *)*ffp);
  else
    interpret_action2(action, ffp, fsp);
}


CC push_closure(struct closure *fn, u8 nargs)
{
  struct code *code = fn->code;
  struct interpret_frame *frame;
  u8 nb_nonargs = code->nb_locals - code->nargs;
  int frame_size;
  u16 i;
  i8 fnargs = code->nargs;
  value *args = (value *)sp;
  struct vector *vargs;
  bool ok;

  MDBG8(dbg_push_closure);
  MDBG16(code);
  MDBG16(sp);

  if (fnargs < 0)
    {
      /* varargs */
      u8 j;

      vargs = (struct vector *)unsafe_allocate_record(type_vector, nargs);

      for (j = 0; j < nargs; j++)
	vargs->data[nargs - j - 1] = args[j];

      /* Pop args from stack and reserve space for vargs */
      sp += nargs * sizeof(value);
      nb_nonargs = code->nb_locals;
    }
  else
    nb_nonargs = code->nb_locals - code->nargs;

  frame_size = offsetof(struct interpret_frame, locals) +
    nb_nonargs * sizeof(value);
  GCPRO1(fn);
  frame = push_frame(interpret_action, frame_size);
  GCPOP(1);

  code = fn->code;
  frame->ins = 0;
  frame->fn = fn;
  for (i = 0; i < nb_nonargs; i++)
    frame->locals[i] = NULL;

#ifndef TINY
  /* Profiling */
  code->call_count++;
  frame->start_ins = instruction_number;
#endif

  if (fnargs < 0)
    /* Save vargs in the right place */
    frame->locals[code->nb_locals - 1] = (value)vargs;
  else
    {
      /* fixed args, already in place, just check number */
      if (nargs != (u8)fnargs)
	{
#ifndef TINY
	  if (context.display_error)
	    actual_args = nargs; /* This is an evil hack */
#endif
	  runtime_error(error_wrong_parameters);
	}
    }

  /* Make local variables */
  allocate_locals(frame->locals, code->nb_locals);

  /* We don't check for infinite loops through function calls because
     these will run out of memory anyway */
}

#if 0
/* This is what push_closure looks like for non-varargs functions, and
   assuming we don't need the GCPRO1 around push_frame and the 
   allocate_locals */
CC testing(struct closure *fn, u8 nargs)
{
  struct interpret_frame *frame;
  u8 nb_nonargs = fn->code->nb_locals - fn->code->nargs;
  int frame_size = offsetof(struct interpret_frame, locals) +
    nb_nonargs * sizeof(value);
  u16 i;

  frame = push_frame(interpret_action, frame_size);
  frame->ins = 0;
  frame->fn = fn;
  for (i = 0; i < nb_nonargs; i++)
    frame->locals[i] = NULL;

  if (nargs != (u8)fn->code->nargs)
    runtime_error(error_wrong_parameters);
}
#endif
