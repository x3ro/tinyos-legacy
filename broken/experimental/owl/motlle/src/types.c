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

#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <errno.h>
#include <math.h>
#include "mudlle.h"
#include "types.h"
#include "alloc.h"

struct closure *unsafe_alloc_and_push_closure(u8 nb_variables)
{
  /* This could (should?) be optimised to avoid the need for
     GCPRO1/stack_reserve/GCPOP */
  struct closure *newp = (struct closure *)unsafe_allocate_record(type_function, nb_variables + 1);

  SET_READONLY(newp);
  GCPRO1(newp);
  stack_reserve(sizeof(value));
  GCPOP(1);
  stack_push(newp);

  return newp;
}

#ifndef STANDALONE
struct closure *alloc_closure0(struct code *code)
{
  struct closure *newp;

  GCCHECK(code);
  GCPRO1(code);
  newp = (struct closure *)allocate_record(type_function, 1);
  GCPOP(1);
  newp->code = code;
  SET_READONLY(newp);

  return newp;
}
#endif

#ifndef TINY
struct string *alloc_string(const char *s)
{
  struct string *newp;

  newp = (struct string *)allocate_string(type_string, strlen(s) + 1);

  strcpy(newp->str, s);

  return newp;
}

struct mudlle_float *alloc_mudlle_float(float d)
{
  struct mudlle_float *newp;

  newp = (struct mudlle_float *)allocate_string(type_float, sizeof newp->d);
  newp->d = d;
  SETFLAGS(newp,  OBJ_READONLY | OBJ_IMMUTABLE);

  return newp;
}

struct symbol *alloc_symbol(struct string *name, value data)
{
  struct symbol *newp;

  GCCHECK(name);
  GCCHECK(data);
  GCPRO2(name, data);
  newp = (struct symbol *)unsafe_allocate_record(type_symbol, 2);
  GCPOP(2);
  newp->name = name;
  newp->data = data;

  return newp;
}

struct symbol *copy_symbol(struct symbol *s)
{
  GCCHECK(s);
  return alloc_symbol(s->name, s->data);
}

struct extptr *alloc_extptr(void *ext)
{
  struct extptr *t = (struct extptr *)allocate_string(type_null, sizeof(struct extptr));
  t->external = ext;
  return t;
}
#endif

struct vector *alloc_vector(uvalue size)
{
  return (struct vector *)allocate_record(type_vector, size);
}

struct vector *copy_vector(struct vector *v)
{
  struct vector *newp;
  uvalue size = vector_len(v);

  GCPRO1(v);
  newp = alloc_vector(size);
  memcpy(newp->data, v->data, size * sizeof(*v->data));
  GCPOP(1);

  return newp;
}  

struct string *alloc_string_n(uvalue n)
{
  struct string *newp;

  newp = (struct string *)allocate_string(type_string, n + 1);
  newp->str[n] = '\0';

  return newp;
}

struct string *copy_string(struct string *s)
{
  struct string *newp;
  uvalue size = string_len(s);

  GCPRO1(s);
  newp = alloc_string_n(size);
  memcpy(newp->str, s->str, size * sizeof(*s->str));
  GCPOP(1);

  return newp;
}  

struct list *alloc_list(value car, value cdr)
{
  struct list *newp;

  GCCHECK(car);
  GCCHECK(cdr);
  GCPRO2(car, cdr);
  newp = (struct list *)unsafe_allocate_record(type_pair, 2);
  GCPOP(2);
  newp->car = car;
  newp->cdr = cdr;

  return newp;
}

bool type_sub(mtype t, mtype of)
/* Returns: TRUE if `t' is a subtype of `of' */
{
  return of == t || of == stype_any ||
    (of == stype_list && (t == type_null || t == type_pair));
}

/*
 * Converts the string strp into an int i and returns 1.
 * On over/underflow or illegal characters, it returns 0.
 */
int mudlle_strtoint(const char *strp, int *i)
{
  int n = 0;
  int lim, limrad;
  int sign, radix;

  while (isspace(*strp)) 
    ++strp;

  if (*strp == '+' || *strp == '-')
    sign = *(strp++) == '-' ? -1 : 1;
  else
    sign = 0;

  /* only allow the sign bit to be set if no + or - and radix != 10 */

  lim = (!sign ? (MAX_TAGGED_INT << 1) + 1 : 
	 sign == -1 ? -MIN_TAGGED_INT : MAX_TAGGED_INT);

  if (*strp == '0' && *(strp + 1) == 'x')
    {
      radix = 16;
      strp += 2;
    }
  else
    {
      radix = 10;
      if (!sign) 
	lim = MAX_TAGGED_INT;
    }

  if (!*strp) 
    return 0;

  limrad = lim / radix;

  for (;;)
    {
      char c = toupper(*(strp++));

      if (!c)
	{ 
	  if (!sign && n & (MAX_TAGGED_INT + 1))
	    n |= 0x80000000;          /* have to extend the sign bit here */
	  *i = sign == - 1 ? -n : n;
	  return 1;
	}

      if (n > limrad)
	return 0;

      n *= radix;
      if (c >= '0' && c <= '9')
	n += c - '0';
      else if (c >= 'A' && c < 'A' - 10 + radix)
	n += c - 'A' + 10;
      else
	return 0;

      if (n > lim)
	return 0;
    }
  
}

extern float strtof (__const char *__restrict __nptr,
		     char **__restrict __endptr) __THROW;

int mudlle_strtofloat(const char *strp, float *d)
{
  char *endp;

#if 0
  if (*strp == '0' && *(strp + 1) == 'f')
    {
      int i;
      char buf[9];
      union {
	double d;
	long l[2];
      } u;

      strp += 2;
      for (i = 0; i < 16; ++i)
	if (!isxdigit(strp[++i]))
	  return 0;
      if (strp[16]) 
	return 0;
	
      u.l[0] = strtol(strp + 8, NULL, 16);
      memcpy(buf, strp, 8);
      buf[8] = 0;
      u.l[1] = strtol(buf, NULL, 16); 

      *d = u.d;
      return 1;
    }
#endif

  *d = strtof(strp, &endp);

  return *strp && !*endp;
}
