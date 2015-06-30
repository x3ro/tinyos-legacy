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

#ifndef CONTEXT_H
#define CONTEXT_H

#include <setjmp.h>
#include "mvalues.h"
#include "types.h"
#ifndef TINY
#include "mudio.h"
#endif

extern u8 exception_signal;	/* Last exception that occured, 0 for none */
extern value exception_value;
CC mthrow(u8 msignal, value val);
/*void throw_handled(void);*/
#define throw_handled() (exception_signal = 0)

struct context
{
#ifndef TINY
  bool display_error;		/* Should error messages be shown if an error
				   occurs in this context ? */
  Mio _mudout, _muderr;
#endif
  u32 call_count;
};

extern struct context context;

void motlle_run1(void);

void context_init(void);
/* Effects: Initialises module */

#endif
