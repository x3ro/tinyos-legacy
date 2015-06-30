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

#ifndef TYPES_H
#define TYPES_H

#include "mvalues.h"

/* The different types */

typedef enum 
{
  /* There are three kinds of types: internal types (never seen by the
     user), user types (the types of actual values) and synthetic types
     (correspond to particular sets of types, e.g., list == null+pair)
  */
  /* These types appear in object's type fields */
  itype_code, 
  type_null,			/* This only appears in objects which have
				   been invalidated (e.g., by dump) */
  type_string,
  type_vector,
  type_pair,
  type_dummy1,
  type_integer,
  type_function,		/* Closure objects have this type */
  itype_variable,
  type_symbol,
  type_table,
  type_outputport,
  type_float,
  /* These types do not appear in actual objects */

  last_type,

  /* Synthetic types */
  stype_none = last_type,	/* no type, the empty set */
  stype_any,			/* All types */
  stype_list,			/* { pair, null } */
  last_synthetic_type,

  itype_implicit,		/* Type of implicitly declared globals,
				   only used internally in global sym table */
} mtype;

bool type_sub(mtype t, mtype of);
/* Returns: TRUE if `t' is a subtype of `of' */

#define ATOM_TYPE(v) type_function
#define ATOM_TO_PRIMITIVE_NB(v) ATOM_VALUE(v)
#define PRIMITIVE_NB_TO_ATOM(n) MAKE_ATOM(n)

#define TYPE(v, want_type) \
  (INTEGERP((v)) ? (want_type) == type_integer : \
   ATOMP((v))    ? (want_type) == ATOM_TYPE((v)) : \
                   ((v) && OBJTYPE(v) == (want_type)))

#define TYPEOF(v) \
  (INTEGERP((v)) ? type_integer : \
   ATOMP((v))    ? ATOM_TYPE(v) : \
   !v            ? type_null : \
		   ((struct obj *)(v))->type)

/* x is a value. Is it a primitive or a closure ? */
#define PRIMITIVEP(x) (ATOMP(x) && ATOM_TYPE(x) == type_function)
#define CLOSUREP(x) (POINTERP(x) && OBJTYPE(x) == type_function)

/* x is a function. Is it  a primitive or a closure ? */
#define FPRIMITIVEP(x) ATOMP(x)
#define FCLOSUREP(x) POINTERP(x)


/* Code is defined in values (it is known to the gc) */

struct closure			/* Is a record */
{
  struct obj o;
  struct code *code;		/* May be type_code, type_mcode, type_primitive
				   as well */
  struct variable *variables[1]; /* May be other types */
};

struct string			/* Is a string */
{
  struct obj o;
  unsigned char str[1];		/* Must be null terminated */
};

struct mudlle_float
{
  struct obj o;
  float d;
};

struct variable			/* Is a record */
{
  /* This is used for type_variable and type_function */
  struct obj o;
  value vvalue;
};

struct symbol			/* Is a record */
{
  struct obj o;
  struct string *name;
  value data;
};

struct extptr
{
  struct obj o;
  void *external;
};

struct vector			/* Is a record */
{
  struct obj o;
  value data[1];
};

struct list			/* Is a record */
{
  struct obj o;
  value car, cdr;
};

struct compile_context		/* Is a record (vector) */
{
  struct obj o;
  struct global_state *gstate;
  value evaluation_state;
};

struct closure *unsafe_alloc_and_push_closure(u8 nb_variables);
struct closure *alloc_closure0(struct code *code);
struct string *alloc_string(const char *s);
struct string *alloc_string_n(uvalue size);
struct symbol *alloc_symbol(struct string *name, value data);
struct vector *alloc_vector(uvalue size);
struct list *alloc_list(value car, value cdr);
struct extptr *alloc_extptr(void *ext);
struct mudlle_float *alloc_mudlle_float(float d);

struct symbol *copy_symbol(struct symbol *s);
struct vector *copy_vector(struct vector *v);
struct string *copy_string(struct string *);

#define string_len(str) ((str)->o.size - (sizeof(struct obj) + 1))
#define vector_len(vec) (((vec)->o.size - sizeof(struct obj)) / sizeof(value))

/* For the time being, 0 is false, everything else is true */
#define istrue(v) ((value)(v) != makebool(FALSE))
/* Make a mudlle boolean from a C boolean (1 or 0) */
#define makebool(i) makeint(!!(i))

#define LOCALSTR(local, from) do {		\
  int __l = string_len(from) + 1;		\
						\
  local = alloca(__l);				\
  memcpy(local, from->str, __l);		\
} while (0)

/*
 * Converts the string sp into an int i and returns 1.
 * On over/underflow or illegal characters, it returns 0.
 */
int mudlle_strtoint(const char *strp, int *i);
int mudlle_strtofloat(const char *strp, float *d);

#endif
