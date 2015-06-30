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

#include <math.h>
#include "runtime/runtime.h"
#include "stringops.h"

TYPEDOP("integer?", isinteger, "x -> b. TRUE if x is an integer", 1, (value x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(INTEGERP(x));
}

TYPEDOP("modulo", modulo, "n1 n2 -> n. n = n1 mod n2", 2, (value v1, value v2),
	  OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "nn.n")
{
  if (INTEGERP(v1) && INTEGERP(v2))
    {
      ivalue result, p1 = intval(v1), p2 = intval(v2);
    
      if (p2 == 0) RUNTIME_ERROR(error_divide_by_zero);
    
      result = p1 % p2;
      if (((p1 < 0 && p2 > 0) || (p1 > 0 && p2 < 0)) && result != 0) result += p2;
      return (makeint(result));
    }
  else RUNTIME_ERROR(error_bad_type);
}

TYPEDOP("max", max, "n1 n2 -> n. n = max(n1, n2)", 2, (value v1, value v2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "nn.n")
{
  value max;

  if (INTEGERP(v1) && INTEGERP(v2)) 
    {
      if ((ivalue)v1 < (ivalue)v2) max = v2;
      else max = v1;
      return (max);
    }
  else RUNTIME_ERROR(error_bad_type);
}

TYPEDOP("min", min, "n1 n2 -> n. n = min(n1, n2)", 2, (value v1, value v2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "nn.n")
{
  value min;

  if (INTEGERP(v1) && INTEGERP(v2)) 
    {
      if ((ivalue)v1 > (ivalue)v2) min = v2;
      else min = v1;
      return (min);
    }
  else RUNTIME_ERROR(error_bad_type);
}

TYPEDOP("abs", abs, "n1 -> n2. n2 = |n1|", 1, (value v),
	  OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "n.n")
{
  ISINT(v);
  if ((ivalue)v < 0) v = makeint(-intval(v));
  return (v);
}

#if DEFINE_GLOBALS
GLOBALS(arith)
{
  system_define("MAXINT", makeint(MAX_TAGGED_INT));
  system_define("MININT", makeint(MIN_TAGGED_INT));
} 
#endif

