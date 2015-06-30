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

#ifndef RUNTIME_H
#define RUNTIME_H

#include "mudlle.h"
#include "types.h"
#include "alloc.h"
#include "global.h"
#include "error.h"
#include "primitives.h"

void runtime_init(void);
void runtime_setup(struct global_state *gstate, int argc, char **argv);

#ifdef PRIMGET
#define FULLOP(name, x, helpmsg, nargs, args, seclevel, flags, type) \
RUNTIME_DEFINE(name, x, nargs)
#define MTYPE(name, sig) 

#elif defined(TINY)
#define FULLOP(name, x, helpmsg, nargs, args, seclevel, flags, type) \
value code_ ## x args

#define MTYPE(name, sig) 

#else
#define FULLOP(name, x, helpmsg, nargs, args, seclevel, flags, type) \
value code_ ## x args; \
struct primitive_ext op_ ## x = { name, helpmsg, code_ ## x, nargs, flags, type }; \
\
value code_ ## x args

#define MTYPE(name, sig) static typing name = { sig, NULL };

#define GLOBALS(name) void name ## _init(void)

#endif

#if defined(PRIMGET) || !defined(STANDALONE)
#define DEFINE_GLOBALS 1
#else
#define DEFINE_GLOBALS 0
#endif

#define TYPEDOP(name, x, helpmsg, nargs, args, flags, type) \
  MTYPE(type_ ## x, type) \
  FULLOP(name, x, helpmsg, nargs, args, 0, flags, type_ ## x)

#define OPERATION(name, x, helpmsg, nargs, args, flags) \
  FULLOP(name, x, helpmsg, nargs, args, 0, flags, NULL)

#define VAROP(name, x, helpmsg, flags) \
  FULLOP(name, x, helpmsg, -1, (int nargs), 0, flags, NULL)

#define SECOP(name, x, helpmsg, nargs, args, seclevel, flags) \
  FULLOP(name, x, helpmsg, nargs, args, seclevel, flags, NULL)

#define UNSAFEOP(name, x, helpmsg, nargs, args, flags) \
  SECOP(name, x, "UNSAFE:" helpmsg, nargs, args, 0, flags)

#define UNIMPLEMENTED(name, x, helpmsg, nargs, args, flags) \
  FULLOP(name, x, "UNIMPLEMENTED: " helpmsg, nargs, args, 0, flags, NULL) \
{ \
  RUNTIME_ERROR(error_bad_function); \
  undefined(); \
}

#define vararg_get(n) stack_get(nargs - (n) - 1)
#define varargs_pop() stack_popn(nargs)

#define IDEF(s) system_define(#s, makeint(s))

void system_define(const char *name, value val);
/* Modifies: environment
   Requires: name not already exist in environment.
   Effects: Adds name to environment, with value val for the variable,
     as a 'define' of the system module.
*/

void define_string_vector(const char *name, const char **vec, int count);


#define RUNTIME_ERROR(n) runtime_error(n)

#define TYPEIS(v, want_type) \
  do if (!TYPE((v), (want_type))) \
    { RUNTIME_ERROR(error_bad_type); } while (0)

#define ISINT(v) \
  do if (!INTEGERP((v))) { RUNTIME_ERROR(error_bad_type); } while (0)

/* Return the undefined result */
#define undefined()  return undefined_value
/* Return a value to shut compiler up */
#define NOTREACHED return 0

/* Typing information for primitives */
/* A type signature is a string xxx.y, where the
   x's stand for the type of arguments, y for the type of the result.
   y can be ommitted for functions with undefined results.
   The following characters are used:

   f: function
   n: integer
   s: string
   v: vector
   l: list (pair or null)
   k: pair
   t: table
   y: symbol
   x: any
   o: other
   1-9: same type as corresponding argument (must be a previous arg)
   A-Z: special typesets, as follows:
    S: string or integer

  A typing is just an array of strings (terminated by NULL).
  Rep chosen for ease of type specification
*/

#endif

