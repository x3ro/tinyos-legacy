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
#include <string.h>

TYPEDOP("new_bitset", new_bitset, "n -> bitset. Returns a bitset usable for storing n bits",
	1, (value n),
	OP_LEAF | OP_NOESCAPE, ".s")
{
  uvalue size;
  struct string *newp;
  
  ISINT(n);
  size = (intval(n) + 7) >> 3;
  newp = alloc_string_n(size);
  
  return newp;
}

TYPEDOP("bcopy", bcopy, "bitset1 -> bitset2. Makes a copy of bitset1",
	1, (struct string *b),
	OP_LEAF | OP_NOESCAPE, "s.s")
{
  struct string *newp;
  ivalue l;
  
  TYPEIS(b, type_string);
  
  l = string_len(b);
  GCPRO1(b);
  newp = alloc_string_n(l);
  GCPOP(1);
  memcpy(newp->str, b->str, l + 1);
  
  return newp;
}

TYPEDOP("bclear", bclear, 
"bitset -> bitset. Clears all bits of bitset and returns it",
	1, (struct string *b),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "s.s")
{
  TYPEIS(b, type_string);
  memset(b->str, 0, string_len(b));
  return b;
}

TYPEDOP("set_bit!", set_bitb, "bitset n -> . Sets bit n of specified bitset",
	2, (struct string *b, value _n),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "sn.")
{
  ivalue n, i;
  
  TYPEIS(b, type_string);
  ISINT(_n); n = intval(_n);
  
  i = n >> 3;
  if (i < 0 || i >= string_len(b)) RUNTIME_ERROR(error_bad_index);
  b->str[i] |= 1 << (n & 7);
  
  undefined();
}

TYPEDOP("clear_bit!", clear_bitb, 
"bitset n -> . Clears bit n of specified bitset",
	2, (struct string *b, value _n),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "sn.")
{
  ivalue n, i;
  
  TYPEIS(b, type_string);
  ISINT(_n); n = intval(_n);
  
  i = n >> 3;
  if (i < 0 || i >= string_len(b)) RUNTIME_ERROR(error_bad_index);
  b->str[i] &= ~(1 << (n & 7));
  
  undefined();
}

TYPEDOP("bit_set?", bit_setp, "bitset n -> b. True if bit n is set",
	2, (struct string *b, value _n),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "sn.n")
{
  ivalue n, i;
  
  TYPEIS(b, type_string);
  ISINT(_n); n = intval(_n);
  i = n >> 3;
  if (i < 0 || i >= string_len(b)) RUNTIME_ERROR(error_bad_index);
  
  return makeint(b->str[i] & 1 << (n & 7));
}

TYPEDOP("bit_clear?", bit_clearp, "bitset n -> b. True if bit n is set",
	2, (struct string *b, value _n),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "sn.n")
{
  ivalue n, i;
  
  TYPEIS(b, type_string);
  ISINT(_n); n = intval(_n);
  i = n >> 3;
  if (i < 0 || i >= string_len(b)) RUNTIME_ERROR(error_bad_index);
  
  return makebool(!(b->str[i] & 1 << (n & 7)));
}

/* All binary ops expect same-sized bitsets */

TYPEDOP("bunion", bunion, 
"bitset1 bitset2 -> bitset3. bitset3 = bitset1 U bitset2",
	2, (struct string *b1, struct string *b2),
	OP_LEAF | OP_NOESCAPE, "ss.s")
{
  struct string *b3;
  char *sb1, *sb2, *sb3;
  ivalue l;
  
  TYPEIS(b1, type_string);
  TYPEIS(b2, type_string);
  l = string_len(b1);
  if (l != string_len(b2)) RUNTIME_ERROR(error_bad_value);
  
  GCPRO2(b1, b2);
  b3 = alloc_string_n(l);
  GCPOP(2);
  
  sb1 = b1->str; sb2 = b2->str; sb3 = b3->str;
  while (l-- >= 0) *sb3++ = *sb1++ | *sb2++;
  
  return b3;
}

TYPEDOP("bintersection", bintersection, 
"bitset1 bitset2 -> bitset3. bitset3 = bitset1 /\\ bitset2",
	2, (struct string *b1, struct string *b2),
	OP_LEAF | OP_NOESCAPE, "ss.s")
{
  struct string *b3;
  char *sb1, *sb2, *sb3;
  ivalue l;
  
  TYPEIS(b1, type_string);
  TYPEIS(b2, type_string);
  l = string_len(b1);
  if (l != string_len(b2)) RUNTIME_ERROR(error_bad_value);
  
  GCPRO2(b1, b2);
  b3 = alloc_string_n(l);
  GCPOP(2);
  
  sb1 = b1->str; sb2 = b2->str; sb3 = b3->str;
  while (l-- >= 0) *sb3++ = *sb1++ & *sb2++;
  
  return b3;
}

TYPEDOP("bdifference", bdifference, 
"bitset1 bitset2 -> bitset3. bitset3 = bitset1 - bitset2",
	2, (struct string *b1, struct string *b2),
	OP_LEAF | OP_NOESCAPE, "ss.s")
{
  struct string *b3;
  char *sb1, *sb2, *sb3;
  ivalue l;
  
  TYPEIS(b1, type_string);
  TYPEIS(b2, type_string);
  l = string_len(b1);
  if (l != string_len(b2)) RUNTIME_ERROR(error_bad_value);
  
  GCPRO2(b1, b2);
  b3 = alloc_string_n(l);
  GCPOP(2);
  
  sb1 = b1->str; sb2 = b2->str; sb3 = b3->str;
  while (l-- >= 0) *sb3++ = *sb1++ & ~*sb2++;
  
  return b3;
}

TYPEDOP("bunion!", bunionb, 
"bitset1 bitset2 -> bitset1. bitset1 = bitset1 U bitset2",
	2, (struct string *b1, struct string *b2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.s")
{
  char *sb1, *sb2;
  ivalue l;
  
  TYPEIS(b1, type_string);
  TYPEIS(b2, type_string);
  l = string_len(b1);
  if (l != string_len(b2)) RUNTIME_ERROR(error_bad_value);
  
  sb1 = b1->str; sb2 = b2->str;
  while (l-- > 0) *sb1++ |= *sb2++;
  
  return b1;
}

TYPEDOP("bintersection!", bintersectionb, 
"bitset1 bitset2 -> bitset1. bitset1 = bitset1 /\\ bitset2",
	2, (struct string *b1, struct string *b2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.s")
{
  char *sb1, *sb2;
  ivalue l;
  
  TYPEIS(b1, type_string);
  TYPEIS(b2, type_string);
  l = string_len(b1);
  if (l != string_len(b2)) RUNTIME_ERROR(error_bad_value);
  
  sb1 = b1->str; sb2 = b2->str;
  while (l-- > 0) *sb1++ &= *sb2++;
  
  return b1;
}

TYPEDOP("bdifference!", bdifferenceb, 
"bitset1 bitset2 -> bitset1. bitset1 = bitset1 - bitset2",
	2, (struct string *b1, struct string *b2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.s")
{
  char *sb1, *sb2;
  ivalue l;
  
  TYPEIS(b1, type_string);
  TYPEIS(b2, type_string);
  l = string_len(b1);
  if (l != string_len(b2)) RUNTIME_ERROR(error_bad_value);
  
  sb1 = b1->str; sb2 = b2->str;
  while (l-- > 0) *sb1++ &= ~*sb2++;
  
  return b1;
}

TYPEDOP("bassign!", bassignb, "bitset1 bitset2 -> bitset1. bitset1 = bitset2",
	2, (struct string *b1, struct string *b2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.s")
{
  ivalue l;
  
  TYPEIS(b1, type_string);
  TYPEIS(b2, type_string);
  l = string_len(b1);
  if (l != string_len(b2)) RUNTIME_ERROR(error_bad_value);
  
  memcpy(b1->str, b2->str, l);
  
  return b1;
}

TYPEDOP("bitset_in?", bitset_inp, 
"bitset1 bitset2 -> b. True if bitset1 is a subset of bitset2",
	2, (struct string *b1, struct string *b2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.n")
{
  char *sb1, *sb2;
  ivalue l;
  
  TYPEIS(b1, type_string);
  TYPEIS(b2, type_string);
  l = string_len(b1);
  if (l != string_len(b2)) RUNTIME_ERROR(error_bad_value);
  
  sb1 = b1->str; sb2 = b2->str;
  while (l-- >= 0) if (*sb1++ & ~*sb2++) return makebool(FALSE);
  
  return makebool(TRUE);
}

TYPEDOP("bitset_eq?", bitset_eqp,
 "bitset1 bitset2 -> b. True if bitset1 == bitset2",
	2, (struct string *b1, struct string *b2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.n")
{
  ivalue l;
  
  TYPEIS(b1, type_string);
  TYPEIS(b2, type_string);
  l = string_len(b1);
  if (l != string_len(b2)) RUNTIME_ERROR(error_bad_value);
  
  return makebool(memcmp(b1->str, b2->str, l) == 0);
}

TYPEDOP("bempty?", bemptyp, "bitset -> b. True if bitset has all bits clear",
	1, (struct string *b),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "s.n")
{
  ivalue l;
  char *sb;
  
  TYPEIS(b, type_string);
  
  l = string_len(b);
  sb = b->str;
  while (l-- > 0)
    if (*sb++) return makebool(FALSE);
  
  return makebool(TRUE);
}

TYPEDOP("bcount", bcount, 
"bitset -> n. Returns the number of bits set in bitset",
	1, (struct string *b),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "s.n")
{
  ivalue l;
  ivalue n;
  char bi, *sb;
  static char count[16] = { 0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4 };
  
  TYPEIS(b, type_string);
  l = string_len(b);
  sb = b->str;
  n = 0;
  while (l-- > 0)
    {
      bi = *sb++;
      n = n + count[bi & 15] + count[(bi >> 4) & 15];
    }
  return makeint(n);
}
