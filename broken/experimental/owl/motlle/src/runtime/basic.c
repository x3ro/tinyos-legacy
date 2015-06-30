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

#include <stdlib.h>
#include <ctype.h>

#include "runtime/runtime.h"
#include "runtime/basic.h"
#include "interpret.h"
#include "alloc.h"
#include "vector.h"
#include "stringops.h"
#include "symbol.h"
#include "call.h"

TYPEDOP("function?", codep, "x -> b. TRUE if x is a function", 1, (value v),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(TYPE(v, type_function));
}

TYPEDOP("apply", apply,
"fn v -> x. Excutes fn with arguments v, returns its result",
	2, (value f, struct vector *args),
	0, "fv.x")
{
  uvalue nargs;
  u8 i, nargs8;
  bool ok;

  TYPEIS(args, type_vector);
  nargs = vector_len(args);
  if (nargs > MAX_ARGS)
    RUNTIME_ERROR(error_wrong_parameters);
  nargs8 = nargs;

  primitive_frame_needed();
  GCPRO1(args);
  stack_reserve(nargs8 * sizeof(value));
  GCPOP(1);
  for (i = 0; i < nargs8; i++)
    stack_push(args->data[i]);
  setup_call_stack(f, nargs8);

  return PRIMITIVE_STOLE_CC;
}

OPERATION("error", error, "n -> . Causes error n", 1, (value errno),
	  OP_NOESCAPE)
{
  ISINT(errno);
  RUNTIME_ERROR((runtime_errors)intval(errno));
}

struct handle_frame {
  struct generic_frame g;
  value handler;
};

static CC handle_action(frameact action, u8 **ffp, u8 **fsp)
{
  u8 *lfp = *ffp;
  struct handle_frame *frame = (struct handle_frame *)lfp;

  switch (action)
    {
    case fa_print:
      mputs("handle_error()" EOL, muderr);
      break;
    case fa_execute:
      {
	value result = stack_pop();

	pop_frame(ffp, fsp, sizeof(struct handle_frame));
	stack_push(result);
	break;
      }
    case fa_gcforward: 
      forward(&frame->handler);
      /* fall through */
    case fa_pop:
      pop_frame(ffp, fsp, sizeof(struct handle_frame));
      break;
    case fa_unwind:
      {
	value handler = frame->handler, val = exception_value;

	throw_handled();
	pop_frame(ffp, fsp, sizeof(struct handle_frame));
	GCPRO2(handler, val);
	stack_reserve(sizeof(value));
	GCPOP(2);
	stack_push(val);
	setup_call_stack(handler, 1);
      }
      break;
    default:
      abort();
    }
}

OPERATION("handle_error", handle_error, 
"fn1 fn2 -> x. Executes fn1(). If an error occurs, calls fn2(errno). \n\
Returns result of fn1 or fn2",
	  2, (value f, value handler),
	  0)
{
  int ok;
  struct handle_frame *frame;

  GCPRO2(handler, f);
  frame = push_frame(handle_action, sizeof(struct handle_frame));
  GCPOP(2);
  frame->handler = handler;
  setup_call_stack(f, 0);

  return PRIMITIVE_STOLE_CC;
}

OPERATION("display_error", display_error,
	  "b1 -> b2. If b1 is false, disable error traces. Returns previous error trace status",
	  1, (value disp), OP_LEAF | OP_NOESCAPE | OP_NOALLOC)
{
  bool ison = context.display_error;

  context.display_error = istrue(disp);

  return makebool(ison);
}

#if 0
static value result;

static void docall0(void *x)
{
  result = call0(x);
}

OPERATION("catch_error", catch_error,
"fn b -> x. Executes fn() and returns its result. If an error occurs,\n\
returns the error number. If b is true, error messages are suppressed",
	  2, (value f, value suppress),
	  0)
{
  callable(f, 0);

  if (mcatch(docall0, f, !istrue(suppress))) return result; /* No error */

  if (exception_signal == SIGNAL_ERROR &&
      exception_value != makeint(error_loop) &&
      exception_value != makeint(error_recurse)) return exception_value;
  mthrow(exception_signal, exception_value);
  NOTREACHED;
}

UNSAFEOP("session", session, "fn -> . Calls fn() in it's own session",
	 1, (struct closure *fn),
	 0)
{
  struct session_context newc;
  value aresult;

  callable(fn, 0);
  session_start(&newc, minlevel, muduser, mudout, muderr);
  aresult = mcatch_call0(fn);
  session_end();

  return aresult;
}
#endif

/* "Object" manipulation:
   load, save, size
   protect, test status, etc
*/

TYPEDOP("immutable?", immutablep,
"x -> b. Returns true if x is an immutable value",
	1, (value x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(immutablep(x));
}

TYPEDOP("readonly?", readonlyp, 
"x -> b. Returns true if x is a read-only value",
	1, (value x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(readonlyp(x));
}

TYPEDOP("protect", protect, "x -> x. Makes value x readonly",
	1, (struct obj *x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.1")
{
  if (POINTERP(x)) 
    SET_READONLY(x);
  return x;
}

TYPEDOP("typeof", typeof, "x -> n. Return type of x",
	1, (value x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makeint(TYPEOF(x));
}

UNSAFEOP("unlimited_execution", unlimited_execution, 
" -> . Disables execution-time limits",
	 0, (void),
	 OP_NOESCAPE)
{
  /*unlimited_execution();*/
  undefined();
}

UNSAFEOP("garbage_collect", garbage_collect, 
" -> . Does a forced garbage collection",
	 0, (void),
	 OP_LEAF)
{
  garbage_collect();
  undefined();
}

#if DEFINE_GLOBALS
GLOBALS(basic)
{
  system_define("true", makebool(TRUE));
  system_define("false", makebool(FALSE));

  define_string_vector("error_messages", mudlle_errors, last_runtime_error);

  /* Errors */
  system_define("error_bad_function", makeint(error_bad_function));
  system_define("error_bad_type", makeint(error_bad_type));
  system_define("error_divide_by_zero", makeint(error_divide_by_zero));
  system_define("error_bad_index", makeint(error_bad_index));
  system_define("error_bad_value", makeint(error_bad_value));
  system_define("error_variable_read_only", makeint(error_variable_read_only));
  system_define("error_loop", makeint(error_loop));
  system_define("error_wrong_parameters", makeint(error_wrong_parameters));
  system_define("error_value_read_only", makeint(error_value_read_only));
  system_define("error_user_interrupt", makeint(error_user_interrupt));
  system_define("error_compile_error", makeint(error_compile_error));
  system_define("error_no_match", makeint(error_no_match));
  system_define("error_no_memory", makeint(error_no_memory));
  system_define("last_runtime_error", makeint(last_runtime_error));

  /* The mudlle types */
  system_define("type_function", makeint(type_function));
  system_define("type_string", makeint(type_string));
  system_define("type_vector", makeint(type_vector));
  system_define("type_pair", makeint(type_pair));
  system_define("type_symbol", makeint(type_symbol));
  system_define("type_table", makeint(type_table));
  system_define("type_outputport", makeint(type_outputport));
  system_define("type_null", makeint(type_null));
  system_define("type_integer", makeint(type_integer));
  system_define("last_type", makeint(last_type));

  /* Synthetic types */
  system_define("stype_none", makeint(stype_none));
  system_define("stype_any", makeint(stype_any));
  system_define("stype_list", makeint(stype_list));
  system_define("last_synthetic_type", makeint(last_synthetic_type));
}
#endif


