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

#ifndef VALUES_H
#define VALUES_H

#include <limits.h>

/* The basic structure of all values */
typedef void *value;
#ifdef AVR
typedef u16 uvalue; /* The correspondingly-sized unsigned integer type */
typedef i16 ivalue;
#else
typedef u32 uvalue; /* The correspondingly-sized unsigned integer type */
typedef i32 ivalue;
#endif

/* Objects are either integers or pointers to more complex things (like
   variables) The low order bit differentiates between the 2, 0 for
   pointers, 1 for integers If the object is a pointer, it is directly
   valid, if an integer the low order bit must be ignored */

#ifdef AVR
#define PRIMITIVE_STOLE_CC ((value)0xfffe)
#define ATOM_BASE 0x8000
#define POINTERP(obj) ((obj) && ((uvalue)(obj) & 1) == 0 && (uvalue)(obj) < ATOM_BASE)
#define INTEGERP(obj) (((uvalue)obj & 1) == 1)
#define ATOMP(obj) ((uvalue)(obj) >= ATOM_BASE && ((uvalue)(obj) & 1) == 0)

#define ATOM_VALUE(v) (((uvalue)(v) - ATOM_BASE) >> 1)
#define MAKE_ATOM(n) ((value)(((n) << 1) + ATOM_BASE))

#else
#define POINTERP(obj) ((obj) && ((uvalue)(obj) & 3) == 0)
#define INTEGERP(obj) (((uvalue)obj & 1) == 1)
#define ATOMP(obj) ((obj) && ((uvalue)(obj) & 3) == 2)
#define PRIMITIVE_STOLE_CC ((value)-2)

#define ATOM_VALUE(v) ((uvalue)(v) >> 2)
#define MAKE_ATOM(n) ((value)(((n) << 2) | 2))
#endif

#define ALIGNMENT sizeof(value)


/* Make & unmake integers */
#define intval(obj) ((ivalue)(obj) >> 1)
#define makeint(i) ((value)(((i) << 1) + 1))

#define INTBITS (8 * sizeof(value) - 2)
#define MAX_TAGGED_INT ((1 << INTBITS) - 1)
#define MIN_TAGGED_INT (-(1 << INTBITS))

#ifdef USE_FLAGS
#define FLAG_BITS 2
#define FLAGS(o) ((o).flags)
#define SETFLAGS(o, f) ((o).flags = (f))
#else
#define FLAG_BITS 0
#define FLAGS(o) 0
#define SETFLAGS(o, f) 
#endif

#ifdef TINY
#define TYPE_BITS 3
#else
#define TYPE_BITS 4
#endif

struct obj 
{
  unsigned type : TYPE_BITS;
#ifdef USE_FLAGS
  unsigned flags : FLAG_BITS;
#endif
  unsigned forwarded : 1;
  unsigned size : (CHAR_BIT * sizeof(value) - TYPE_BITS - FLAG_BITS - 1);
};

#ifdef AVR
/* Better code this way */
#define OBJTYPE(o) (*(u8 *)(o) & ((1 << TYPE_BITS) - 1))
#else
#define OBJTYPE(o) (((struct obj *)(o))->type)
#endif

#define OBJ_READONLY 1		/* Used for some values */
#define OBJ_IMMUTABLE 2		/* Contains only pointers to other immutable
				   objects.
				   Its pointers are never modified after 
				   allocation + initialisation (and all
				   initialisation must be done before any other
				   allocation) */

/* True if x is immutable */
#define immutablep(x) \
  (!POINTERP((x)) || (FLAGS(*((struct obj *)(x))) & OBJ_IMMUTABLE) != 0)

/* True if x is readonly */
#define readonlyp(x) \
  (!POINTERP((x)) || (FLAGS(*((struct obj *)(x))) & OBJ_READONLY) != 0)

#define SET_IMMUTABLE(x) \
  SETFLAGS(*((struct obj *)x), FLAGS(*((struct obj *)x) | OBJ_IMMUTABLE))

#define SET_READONLY(x) \
  SETFLAGS(*((struct obj *)x), FLAGS(*((struct obj *)x) | OBJ_READONLY))

/* The basic classes of all objects, as seen by the garbage collector */
/* As far as the garbage collector is concerned, there are:
   strings (gstring) with no pointers
   records (grercord) with only pointers 
   code (code) as specified below
*/
/* How each class of object is structured */

struct gstring
{
  struct obj o;
  char data[1];
};

struct grecord
{
  struct obj o;
  struct obj *data[1];		/* Pointers to other objects */
};

#include "code.h"

struct code
{
  struct obj o;
  u8 nb_locals;
#ifndef AVR
  u8 stkdepth;
  u32 call_count;		/* Profiling */
  u32 instruction_count;
  struct string *varname;
  struct string *filename;
  struct string *help;
  u16 lineno;
#endif
  i8 nargs;			/* -1 for varargs */
  instruction ins[1/*variable size*/];
};

/* These must fit in 7 bits */
#define MAX_ARGS 127
#define MAX_LOCALS 127
#define MAX_CLOSURE 127

#define code_length(c) ((c)->o.size - offsetof(struct code, ins))

#endif
