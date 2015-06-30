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

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include "runtime/runtime.h"
#include "stringops.h"
#include "print.h"
#include "ports.h"

TYPEDOP("string?", stringp, "x -> b. TRUE if x is a string", 1, (value v),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(TYPE(v, type_string));
}

TYPEDOP("make_string", make_string,
"n -> s. Create an empty string of length n",
	1, (value size),
	OP_LEAF | OP_NOESCAPE, "n.s")
{
  struct string *newp;

  ISINT(size);
  if(intval(size) < 0)
    RUNTIME_ERROR(error_bad_value);
  newp = alloc_string_n(intval(size));
  
  return (newp);
}

TYPEDOP("string_length", string_length, "s -> n. Return length of string", 
	1, (struct string *str),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "s.n")
{
  TYPEIS(str, type_string);
  return (makeint(string_len(str)));
}

TYPEDOP("string_downcase", downcase, 
"s -> s. Returns a copy of s with all characters lower case",
	1, (struct string *s),
	OP_LEAF | OP_NOESCAPE, "s.s")
{
  struct string *newp;
  char *s1, *s2;

  TYPEIS(s, type_string);
  GCPRO1(s);
  newp = alloc_string_n(string_len(s));
  GCPOP(1);

  s1 = s->str; s2 = newp->str;
  while ((*s2++ = tolower(*s1++)))
    ;

  return newp;
}  

TYPEDOP("string_upcase", upcase, 
"s -> s. Returns a copy of s with all characters upper case",
	1, (struct string *s),
	OP_LEAF | OP_NOESCAPE, "s.s")
{
  struct string *newp;
  char *s1, *s2;

  TYPEIS(s, type_string);
  GCPRO1(s);
  newp = alloc_string_n(string_len(s));
  GCPOP(1);

  s1 = s->str; s2 = newp->str;
  while ((*s2++ = toupper(*s1++))) 
    ;

  return newp;
}  

TYPEDOP("string_fill!", string_fillb, 
"s n -> . Set all characters of s to character whose code is n",
	2, (struct string *str, value c),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "sn.")
{
  TYPEIS(str, type_string);
  ISINT(c);

  memset(str->str, intval(c), string_len(str));
  undefined();
}

value code_string_ref(struct string *str, value c)
{
  ivalue idx;

  TYPEIS(str, type_string);
  ISINT(c);

  idx = intval(c);
  if (idx < 0 || idx >= string_len(str)) RUNTIME_ERROR(error_bad_index);
  return (makeint((unsigned char)str->str[idx]));
}

value code_string_set(struct string *str, value i, value c)
{
  ivalue idx;

  TYPEIS(str, type_string);
  if (readonlyp(str)) RUNTIME_ERROR(error_value_read_only);
  ISINT(i);
  ISINT(c);

  idx = intval(i);
  if (idx < 0 || idx >= string_len(str)) RUNTIME_ERROR(error_bad_index);
  str->str[idx] = intval(c);

  return c;
}

TYPEDOP("string_cmp", string_cmp, 
"s1 s2 -> n. Compare 2 strings. Returns 0 if s1 = s2, < 0 if s1 < s2 and \n\
> 0 if s1 > s2",
	2, (struct string *s1, struct string *s2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.n")
{
  uvalue l1, l2, i;
  char *t1, *t2;
  int res;

  TYPEIS(s1, type_string);
  TYPEIS(s2, type_string);

  l1 = string_len(s1);
  l2 = string_len(s2);
  t1 = s1->str;
  t2 = s2->str;
  
  i = 0;
  do {
    if (i == l1) { res = i - l2; break; }
    if (i == l2) { res = 1; break; }
    if ((res = *t1++ - *t2++))
      break;
    i++;
  } while (1);
  return (makeint(res));
}

TYPEDOP("string_icmp", string_icmp, 
"s1 s2 -> n. Compare 2 strings ignoring accentuation and case.\n\
Returns 0 if s1 = s2, < 0 if s1 < s2 and > 0 if s1 > s2",
	2, (struct string *s1, struct string *s2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.n")
{
  uvalue l1, l2, i;
  char *t1, *t2;
  int res;

  TYPEIS(s1, type_string);
  TYPEIS(s2, type_string);

  l1 = string_len(s1);
  l2 = string_len(s2);
  t1 = s1->str;
  t2 = s2->str;
  
  i = 0;
  do {
    if (i == l1) { res = i - l2; break; }
    if (i == l2) { res = 1; break; }
    if ((res = tolower(*t1) - tolower(*t2)))
      break;
    t1++; t2++; i++;
  } while (1);
  return (makeint(res));
}

TYPEDOP("string_search", string_search, 
"s1 s2 -> n. Searches in string s1 for string s2.\n\
Returns -1 if not found, index of first matching character otherwise.",
	2, (struct string *s1, struct string *s2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.n")
{
  uvalue l1, l2, i, j, i1;
  char *t1, *t2, lastc2;

  TYPEIS(s1, type_string);
  TYPEIS(s2, type_string);

  l1 = string_len(s1);
  l2 = string_len(s2);

  /* Immediate termination conditions */
  if (l2 == 0) return makeint(0);
  if (l2 > l1) return makeint(-1);

  t1 = s1->str;
  t2 = s2->str;
  lastc2 = t2[l2 - 1];
  
  i = l2 - 1; /* No point in starting earlier */
  for (;;)
    {
      /* Search for lastc2 in t1 starting at i */
      while (t1[i] != lastc2)
	if (++i == l1) return makeint(-1);

      /* Check if rest of string matches */
      j = l2 - 1;
      i1 = i;
      do
	if (j == 0) return makeint(i1); /* match found at i1 */
      while (t2[--j] == t1[--i1]);

      /* No match. If we wanted better efficiency, we could skip over
	 more than one character here (depending on where the next to
	 last 'lastc2' is in s2.
	 Probably not worth the bother for short strings */
      if (++i == l1) return makeint(-1); /* Might be end of s1 */
    }
}

TYPEDOP("string_isearch", string_isearch, 
"s1 s2 -> n. Searches in string s1 for string s2 (case- and accentuation-\n\
insensitive). Returns -1 if not found, index of first matching character\n\
otherwise.",
	2, (struct string *s1, struct string *s2),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "ss.n")
{
#ifndef PRIMGET
  uvalue l1, l2, i, j, i1;
  char *t1, *t2, lastc2;

  TYPEIS(s1, type_string);
  TYPEIS(s2, type_string);

  l1 = string_len(s1);
  l2 = string_len(s2);

  /* Immediate termination conditions */
  if (l2 == 0) return makeint(0);
  if (l2 > l1) return makeint(-1);

  t1 = s1->str;
  t2 = s2->str;
  lastc2 = tolower(t2[l2 - 1]);
  
  i = l2 - 1; /* No point in starting earlier */
  for (;;)
    {
      /* Search for lastc2 in t1 starting at i */
      while (tolower(t1[i]) != lastc2)
	if (++i == l1) return makeint(-1);

      /* Check if rest of string matches */
      j = l2 - 1;
      i1 = i;
      do
	{
	  if (j == 0) return makeint(i1); /* match found at i1 */
	  --j; --i1;
	}
      while (tolower(t2[j]) == tolower(t1[i1]));

      /* No match. If we wanted better efficiency, we could skip over
	 more than one character here (depending on where the next to
	 last 'lastc2' is in s2.
	 Probably not worth the bother for short strings */
      if (++i == l1) return makeint(-1); /* Might be end of s1 */
    }
#endif
}

TYPEDOP("substring", substring, 
"s1 n1 n2 -> s2. Extract substring of s starting at n1 of length n2.\n\
The first character is numbered 0",
	3, (struct string *s, value start, value length),
	OP_LEAF | OP_NOESCAPE, "snn.s")
{
  struct string *newp;
  ivalue first, size;

  TYPEIS(s, type_string);
  ISINT(start);
  ISINT(length);

  first = intval(start);
  size = intval(length);
  if (first < 0 || size < 0 || first + size > string_len(s))
    RUNTIME_ERROR(error_bad_index);

  GCPRO1(s);
  newp = alloc_string_n(size);
  GCPOP(1);
  memcpy(newp->str, s->str + first, size);

  return (newp);
}

value string_append(struct string *s1, struct string *s2)
{
  struct string *newp;
  uvalue l1, l2;

  l1 = string_len(s1);
  l2 = string_len(s2);

  GCPRO2(s1, s2);
  newp = alloc_string_n(l1 + l2);
  GCPOP(2);
  memcpy(newp->str, s1->str, l1);
  memcpy(newp->str + l1, s2->str, l2);

  return (newp);
}

TYPEDOP("string_append", string_append, "s1 s2 -> s. Concatenate s1 and s2",
	  2, (struct string *s1, struct string *s2),
	  OP_LEAF | OP_NOESCAPE, "ss.s")
{
  TYPEIS(s1, type_string);
  TYPEIS(s2, type_string);
  return string_append(s1, s2);
}

TYPEDOP("split_words", split_words, 
"s -> l. Split string s into words in list l",
	1, (struct string *s),
	OP_LEAF | OP_NOESCAPE, "s.l")
{
  struct list *l = NULL, *last = NULL;
  struct string *wrd;
  int len;
  char *scan, *end, missing;

  TYPEIS(s, type_string);

  scan = s->str;
  GCPRO2(l, last);

  do {
    while (*scan == ' ') scan++;

    missing = 0;
    if (*scan == '\'' || *scan == '\"') /* Quoted words */
      {
	end = scan + 1;
	while (*end && *end != *scan) end++;
	/* Be nice: add missing quote */
	if (!*end) missing = *scan;
	else end++;
      }
    else
      {
	end = scan;
	while (*end && *end != ' ') end++;

	if (end == scan) break;
      }

    len = end - scan + (missing != 0);
    wrd = alloc_string_n(len);
    memcpy(wrd->str, scan, len);
    if (missing) wrd->str[len - 1] = missing;
    
    scan = end;

    if (!l) l = last = alloc_list(wrd, NULL);
    else 
      {
	last->cdr = alloc_list(wrd, NULL);
	last = last->cdr;
      }
  } while (1);

  GCPOP(2);

  return (l);
}

TYPEDOP("atoi", atoi, 
"s -> n. Converts string into integer. Returns s if conversion failed",
	1, (struct string *s),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "s.S")
{
  int n;

  TYPEIS(s, type_string);
  if (!mudlle_strtoint(s->str, &n))
    return s;
  else
    return makeint(n);
}

TYPEDOP("itoa", itoa, "n -> s. Converts integer into string", 1, (value n),
	  OP_LEAF | OP_NOESCAPE, "n.s")
{
  char buf[16];

  ISINT(n);
  sprintf(buf, "%ld", intval(n));
  return alloc_string(buf);
}

TYPEDOP("calpha?", isalpha, 
"n -> b. TRUE if n is a letter (allowed in keywords)",
	1, (value n),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "n.n")
{
  ISINT(n);
  return makebool(isalpha(intval(n)));
}

TYPEDOP("cprint?", isprint, "n -> b. TRUE if n is a printable character", 
	1, (value n),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "n.n")
{
  ISINT(n);
  return makebool(isprint(intval(n)));
}

TYPEDOP("cupper", toupper, "n -> n. Return n's uppercase variant", 
	1, (value n),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "n.n")
{
  ISINT(n);
  return makeint(toupper(intval(n)));
}

TYPEDOP("clower", tolower, "n -> n. Return n's lowercase variant", 
	1, (value n),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "n.n")
{
  ISINT(n);
  return makeint(tolower(intval(n)));
}

#if DEFINE_GLOBALS
GLOBALS(string)
{
  struct string *s = 0;

  s = alloc_string("\n");
  SET_READONLY(s);
  system_define("NL", s);
  s = alloc_string("\r\n");
  SET_READONLY(s);
  system_define("CRLF", s);
}
#endif
