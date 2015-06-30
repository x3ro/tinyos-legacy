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

#ifndef AVR_VALUES_H
#define AVR_VALUES_H

/* The basic structure of all values */
typedef u16 avr_value;
typedef u16 avr_uvalue; /* The correspondingly-sized unsigned integer type */
typedef i16 avr_ivalue;

#define AVR_ATOM_BASE 0x8000
#define AVR_POINTERP(obj) ((obj) && ((avr_uvalue)(obj) & 1) == 0 && (avr_uvalue)(obj) < ATOM_BASE)
#define AVR_INTEGERP(obj) (((avr_uvalue)obj & 1) == 1)
#define AVR_ATOMP(obj) ((avr_uvalue)(obj) >= ATOM_BASE && ((avr_uvalue)(obj) & 1) == 0)

#define AVR_ATOM_VALUE(v) (((avr_uvalue)(v) - AVR_ATOM_BASE) >> 1)
#define AVR_MAKE_ATOM(n) ((avr_value)(((n) << 1) + AVR_ATOM_BASE))


#define AVR_ALIGNMENT sizeof(avr_value)

#ifdef AVR_USE_FLAGS
#define AVR_FLAG_BITS 2
#define AVR_FLAGS(o) ((o).flags)
#define AVR_SETFLAGS(o, f) ((o).flags = (f))
#else
#define AVR_FLAG_BITS 0
#define AVR_FLAGS(o) 0
#define AVR_SETFLAGS(o, f) 
#endif

#define AVR_TYPE_BITS 3

struct avr_obj 
{
  unsigned type : AVR_TYPE_BITS;
#ifdef AVR_USE_FLAGS
  unsigned flags : AVR_FLAG_BITS;
#endif
  unsigned forwarded : 1;
  unsigned size : (CHAR_BIT * sizeof(avr_value) - AVR_TYPE_BITS - AVR_FLAG_BITS - 1);
} __attribute__ ((packed));

struct avr_gstring
{
  struct avr_obj o;
  char data[1];
};

struct avr_grecord
{
  struct avr_obj o;
  avr_value data[1];
};

struct avr_code
{
  struct avr_obj o;
  u8 nb_locals;
  i8 nargs;			/* -1 for varargs */
  instruction ins[1/*variable size*/];
};

#define avr_code_length(c) ((c)->o.size - offsetof(struct avr_code, ins))

#define AVR_RINSCST(p) (*(avr_value *)(p))
#define AVR_WINSCST(p, v) (*(avr_value *)(p) = (v))

#endif
