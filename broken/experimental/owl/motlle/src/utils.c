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

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "mudlle.h"
#include "mudio.h"
#include "utils.h"
#ifdef MUME
#  include "macro.h"
#  include "config.h"
#else
#  include "options.h"
#endif

char *strlwr(char *s)
{
  char *t = s;

  while (*t) { *t = tolower(*t); t++; }

  return s;
}

#ifdef DEBUG_MEMORY
void *debug_xmalloc(const char *file, int line, size_t size)
{
  void *newp = debug_malloc(file, line, size);

  if (!newp)
    {
      fprintf(stderr, "No memory!\n");
      abort();
    }

  return newp;
}

void *debug_xcalloc(const char *file, int line, int number, size_t size)
{
  void *newp = debug_calloc(file, line, number, size);

  if (!newp) abort();

  return newp;
}

void *debug_xrealloc(const char *file, int line, void *old, size_t size)
{
  void *newp = debug_realloc(file, line, old, size);

  if (!newp) abort();

  return newp;
}

char *debug_xstrdup(const char *file, int line, const char *s)
{
  char *newp = debug_xmalloc(file, line, strlen(s) + 1);

  return strcpy(newp, s);
}
#else
void *xmalloc(size_t size)
{
  void *newp = malloc(size);

  if (!newp) abort();

  return newp;
}

void *xcalloc(size_t number, size_t size)
{
  void *newp = calloc(number, size);

  if (!newp) abort();

  return newp;
}

void *xrealloc(void *old, size_t size)
{
  void *newp = realloc(old, size);

  if (!newp) abort();

  return newp;
}

char *xstrdup(const char *s)
{
  char *newp = xmalloc(strlen(s) + 1);

  return strcpy(newp, s);
}
#endif
