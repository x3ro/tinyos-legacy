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
#include "interpret.h"

TYPEDOP("cons", cons, "x1 x2 -> l. Make a new pair from elements x1 & x2",
	2, (value car, value cdr),
	OP_LEAF | OP_NOESCAPE, "xx.k")
{
  return alloc_list(car, cdr);
}

TYPEDOP("car", car, "l -> x. Returns first element of pair l", 
	1, (struct list *l),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "k.x")
{
  TYPEIS(l, type_pair);
  return l->car;
}

TYPEDOP("cdr", cdr, "l -> x. Returns 2nd element of pair l", 
	1, (struct list *l),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "k.x")
{
  TYPEIS(l, type_pair);
  return l->cdr;
}

TYPEDOP("pair?", pairp, "x -> b. Returns TRUE if x is a pair", 1, (value v),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(TYPE(v, type_pair));
}

TYPEDOP("list?", listp, "x -> b. Returns TRUE if x is a pair or null", 
	1, (value v),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(!v || TYPE(v, type_pair));
}

TYPEDOP("null?", nullp, "x -> b. Returns TRUE if x is the null object", 
	1, (value v),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(v == NULL);
}

TYPEDOP("set_car!", setcar, "l x ->. Sets the first element of pair l to x",
	2, (struct list *l, value x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "kx.")
{
  TYPEIS(l, type_pair);
  if (readonlyp(l)) RUNTIME_ERROR(error_value_read_only);
  l->car = x;
  undefined();
}

TYPEDOP("set_cdr!", setcdr, "l x ->. Sets the 2nd element of pair l to x",
	2, (struct list *l, value x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "kx.")
{
  TYPEIS(l, type_pair);
  if (readonlyp(l)) RUNTIME_ERROR(error_value_read_only);
  l->cdr = x;
  undefined();
}

VAROP("list", list, "x1 ... -> l. Returns a list of the arguments",
      OP_LEAF)
{
  struct list *l;

  l = NULL;
  GCPRO1(l);

  while (nargs-- > 0)
    l = alloc_list(stack_pop(), l);

  GCPOP(1);
  return l;
}

#if DEFINE_GLOBALS
GLOBALS(list)
{
  system_define("null", NULL);
}
#endif
