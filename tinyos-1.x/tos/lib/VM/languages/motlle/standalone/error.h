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

#ifndef RUNTIME_ERROR_H
#define RUNTIME_ERROR_H

#include <setjmp.h>

#define SIGNAL_ERROR 1

enum { 
  error_bad_function,
  error_bad_type,
  error_divide_by_zero,
  error_bad_index,
  error_bad_value,
  error_variable_read_only,
  error_loop,
  error_wrong_parameters,
  error_value_read_only,
  error_user_interrupt,
  error_no_match,
  error_compile_error,
  error_no_memory,
  last_runtime_error,
  internal_error_print_too_complex = last_runtime_error,
  last_internal_error
};
typedef u8 runtime_errors;

extern const char *mudlle_errors[last_runtime_error];

CC runtime_error(runtime_errors error) NORETURN;
/* Effects: Runtime error 'error' has occured in a primitive operation. 
     Dump the call_stack (plus the primitive operation call) to
     muderr & throw back to the exception handler with SIGNAL_ERROR
     and the error code in exception_value.
*/

int protect(void (*fn)(void *data), void *data);

#endif

