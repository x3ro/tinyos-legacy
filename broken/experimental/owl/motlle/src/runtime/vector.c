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

#include "runtime/runtime.h"
#include "vector.h"

TYPEDOP("vector?", vectorp, "x -> b. TRUE if x is a vector", 1, (value v),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(TYPE(v, type_vector));
}

TYPEDOP("make_vector", make_vector, 
"n -> v. Create an empty vector of length n",
	1, (value size),
	OP_LEAF | OP_NOESCAPE, "n.v")
{
  ISINT(size);
  if(intval(size) < 0)
    RUNTIME_ERROR(error_bad_value);

  return alloc_vector(intval(size));
}

TYPEDOP("vector_length", vector_length, "v -> n. Return length of vector", 
	1, (struct vector *vec),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "v.n")
{
  TYPEIS(vec, type_vector);
  return (makeint(vector_len(vec)));
}

TYPEDOP("vector_fill!", vector_fillb, "v x -> . Set all elements of v to x",
	2, (struct vector *vec, value x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "vx.")
{
  value *fill;
  uvalue len;

  TYPEIS(vec, type_vector);

  len = vector_len(vec);
  for (fill = vec->data; len; fill++, len--) *fill = x;
  undefined();
}

static struct vector *make_vector(u8 nargs)
{
  struct vector *v = (struct vector *)unsafe_allocate_record(type_vector, nargs);

  while (nargs > 0)
    v->data[--nargs] = stack_pop();

  return v;
  
}

VAROP("vector", vector, "x1 ... -> v. Returns a vector of the arguments",
      OP_LEAF)
{
  return make_vector(nargs);
}

VAROP("sequence", sequence, 
"x1 ... -> v. Returns a sequence (readonly vector) of the arguments",
      OP_LEAF)
{
  struct vector *args = make_vector(nargs);

  SET_READONLY(args);

  return args;
}
