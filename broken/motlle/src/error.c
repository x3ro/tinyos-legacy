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
#include <stddef.h>

#include "runtime/runtime.h"
#include "error.h"
#include "call.h"

/* This is a bit annoying */
static struct sjmpbuf
{
  jmp_buf jb;
} *error_destination;

int protect(void (*fn)(void *data), void *data)
{
  struct sjmpbuf error_exit;
  runtime_errors err;
  struct sjmpbuf *old_error_dest = error_destination;
  value **volatile old_gcpro = gcpro;

  error_destination = &error_exit;
  err = setjmp(error_exit.jb);
  if (!(err = setjmp(error_exit.jb)))
    {
      fn(data);
      assert(gcpro == old_gcpro);
      error_destination = old_error_dest;
      return -1;
    }
  else
    {
      error_destination = old_error_dest;
      gcpro = old_gcpro;
      return err - 1;
    }
}

#ifdef TINY
CC runtime_error(u8 error)
/* Effects: Runtime error 'error' has occured. Dump the call_stack to
     muderr & throw back to the exception handler with SIGNAL_ERROR
     and the error code in exception_value.
*/
{
  longjmp(error_destination->jb, error + 1);
}
#else
#include "mudio.h"
#include "print.h"

const char *mudlle_errors[last_runtime_error] = {
  "bad function",
  "bad type",
  "divide by zero",
  "bad index",
  "bad value",
  "variable is read-only",
  "function probably has an infinite loop",
  "wrong number of parameters",
  "value is read only",
  "user interrupt",
  "pattern not matched",
  "compile error",
  "out of memory"
};

static void print_error(int error)
{
  if (error < last_runtime_error && error >= 0)
    mprintf(muderr, "%s" EOL, mudlle_errors[error]);
  else
    mprintf(muderr, "error %d" EOL, error);
  mprintf(muderr, "Call trace is:" EOL);
}

CC runtime_error(u8 error)
/* Effects: Runtime error 'error' has occured. Dump the call_stack to
     muderr & throw back to the exception handler with SIGNAL_ERROR
     and the error code in exception_value.
*/
{
  /* If there's no memory, we might get a 2nd no memory error during error
     display */
  if (context.display_error && muderr &&
      !(error >= last_runtime_error && error < last_internal_error))
    {
      u8 *scanfp = fp, *scansp = sp;
      static bool reentered = FALSE;

      if (reentered)
	{
	  /* Oops. The only possible error at this point is no memory,
	     but I'll leave this is as general code */
	  fflush(stderr);
	  if (error < last_runtime_error)
	    fprintf(stderr, "%s [double]" EOL, mudlle_errors[error]);
	  else
	    fprintf(stderr, "error %d [double]" EOL, error);
	}
      else
	{
	  reentered = TRUE;

	  if (mudout) mflush(mudout);
	  print_error(error);

	  while (scansp < memory + MEMORY_SIZE)
	    {
	      FA_PRINT(&scanfp, &scansp);
	      FA_POP(&scanfp, &scansp);
	    }
	}
      reentered = FALSE;
    }
  longjmp(error_destination->jb, error + 1);
}
#endif
