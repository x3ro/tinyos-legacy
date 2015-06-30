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

#ifndef UTILS_H
#define UTILS_H

#include "options.h"

#define ALIGN(x, n) (((x) + (n) - 1) & ~((n) - 1))

char *strlwr(char *s);

#ifdef DEBUG_MEMORY
void *debug_xmalloc(const char *file, int line, size_t size);
void *debug_xcalloc(const char *file, int line, int number, size_t size);
void *debug_xrealloc(const char *file, int line, void *old, size_t size);
char *debug_xstrdup(const char *file, int line, const char *s);
#else
void *xmalloc(size_t size);
void *xcalloc(size_t number, size_t size);
void *xrealloc(void *old, size_t size);
char *xstrdup(const char *s);
#endif

#endif
