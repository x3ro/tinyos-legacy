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

#ifndef MUDLLE_H
#define MUDLLE_H

/* Generally useful declarations for the mudlle (pronounced muddle)
   interpreter */


#ifdef NO_ASSERT
#define assert(x)
#else
#include <assert.h>
#endif

#include <stdlib.h>
#include <inttypes.h>
#include "options.h"

/* CC functions steal the current continuation. You must not do ANYTHING
   after calling a CC function (it may change the current motlle stack) */
typedef void CC;

/* condCC functions steal the current continuation if their result is
   TRUE. 
*/
typedef bool condCC;

#include "mvalues.h"
#include "memory.h"
#include "context.h"
#include "alloc.h"
#include "error.h"

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef NULL
#define NULL ((void *)0)
#endif

#define mvalue value
#include "motlle-interface.h"
#undef mvalue

#define PACKET_SIZE 29

#ifdef MDBG
#define MDBGLEDS(x) motlle_req_leds(led_ ## x)
#define MDBG8(v) motlle_req_dbg((uint8_t)(v))
#define MDBG16(v) (motlle_req_dbg((uvalue)(v) >> 8), motlle_req_dbg((uvalue)(v) & 0xff))
#else
#define MDBGLEDS(x) 
#define MDBG8(v) 
#define MDBG16(v) 
#endif

extern int debug_lvl;

typedef struct location
{
  const char *filename;
  int lineno;
} location;

#endif
