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

#include <stddef.h>
#include "mudlle.h"
#include "alloc.h"
#include "interpret.h"
#include "error.h"
#include "call.h"
#include "primitives.h"
#include "global.h"

#ifdef TINY
/* Don't waste memory on this, it's just for nice error traces */
#define lazy_setup_primitive_frame(primop, nargs) TRUE
#else
struct primitive_frame
{
  struct generic_frame g;
  struct primitive_ext *op;
  u8 nargs;
  value args[1/*n*/];
};

static void primitive_action(frameact action, u8 **ffp, u8 **fsp)
{
  struct primitive_frame *frame = (struct primitive_frame *)*ffp;
  u8 i;

  switch (action)
    {
    case fa_execute: {
      value result = stack_pop();
      /* Pop frame */
      FA_POP(&fp, &sp);
      stack_push(result);
      break;
    }
    case fa_print: {
      bool first = TRUE;

      mprintf(muderr, "%s(", frame->op->name);
      for (i = 0; i < frame->nargs; i++)
	{
	  if (!first) mputs(", ", muderr);
	  mprint(muderr, prt_print, frame->args[frame->nargs - i - 1]);
	  first = FALSE;
	}
      mputs(")" EOL, muderr);
      break;
    }
    case fa_gcforward:
      for (i = 0; i < frame->nargs; i++)
	forward(&frame->args[i]);
      /* fall through */
    case fa_unwind: case fa_pop: {
      uvalue size;

      size = offsetof(struct primitive_frame, args);
      if (frame->op->nargs >= 0)
	size += frame->nargs * sizeof(value);

      pop_frame(ffp, fsp, size);
      break;
    }
    default: assert(0);
    }
}

static struct primitive_ext *called_op;
static struct vector *called_args;
static u8 called_nargs;

void primitive_frame_needed(void)
{
  struct primitive_frame *frame;
  u8 i;
  uvalue size;

  size = offsetof(struct primitive_frame, args);
  if (called_op->nargs >= 0)
    size += called_nargs * sizeof(value);

  frame = push_frame(primitive_action, size);
  frame->op = called_op;
  frame->nargs = called_nargs;

  if (called_op->nargs >= 0)
    for (i = 0; i < called_nargs; i++)
      frame->args[called_nargs - i - 1] = called_args->data[i];
}

static void lazy_setup_primitive_frame(struct primitive_ext *primop, u8 nargs)
{
  called_op = primop;
  called_nargs = nargs;
  if (primop->nargs >= 0) /* varargs args stay on the stack, don't copy them */
    {
      u8 i;

      if (nargs > vector_len(called_args))
	called_args = alloc_vector(nargs + 4);

      for (i = 0; i < nargs; i++)
	called_args->data[i] = stack_get(nargs - i - 1);
    }
}

void call_init(void)
{
  called_args = alloc_vector(8);
  staticpro((value *)&called_args);
}
#endif

CC push_primitive(value c, u8 nargs)
{
  value arg1, arg2, arg3, result;
  value (*op)();
  i8 pargs;

  lazy_setup_primitive_frame(PRIMOP(globals, c), nargs);

  PRIMCALLED(c);
  op = PRIMFN(c);
  pargs = PRIMARGS(c);
  if (pargs < 0)
    result = op((int)nargs);
  else
    {
      if ((u8)pargs != nargs)
	{
#ifndef TINY
	  stack_popn(nargs);
	  primitive_frame_needed();
#endif
	  runtime_error(error_wrong_parameters);
	}
      switch (pargs)
	{
	case 0:
	  result = op();
	  break;
	case 1:
	  arg1 = stack_pop();
	  result = op(arg1);
	  break;
	case 2:
	  arg2 = stack_pop();
	  arg1 = stack_pop();
	  result = op(arg1, arg2);
	  break;
#ifndef TINY
	case 3:
	  arg3 = stack_pop();
	  arg2 = stack_pop();
	  arg1 = stack_pop();
	  result = op(arg1, arg2, arg3);
	  break;
#endif
	default:
	  result = NULL;
	  assert(0);
	}
    }

  if (result != PRIMITIVE_STOLE_CC)
    {
      GCPRO1(result);
      stack_reserve(sizeof(value));
      GCPOP(1);
      stack_push(result);
    }
}

CC setup_call_stack(value c, u8 nargs)
/* Effects: Puts a call to c with nargs arguments from the motlle stack, on
     the mottle stack.
*/
{
  if (PRIMITIVEP(c))
    push_primitive(c, nargs);
  else if (CLOSUREP(c))
    push_closure(c, nargs);
  else
    runtime_error(error_bad_function);
}
