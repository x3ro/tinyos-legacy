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

#ifndef CODE_H
#define CODE_H

#include <limits.h>

/* Definition of generated code */

/* A bytecode style representation is used:
   Code to be interpreted is an array of bytes.
   Each instruction is stored in 1 byte, followed by an optional 1 or 2 byte
   argument.

   arg0 means no argument.
   arg1 means a byte argument.
   arg2 means a 2 byte argument (big-endian format). */

typedef u8 instruction;

typedef enum { local_var, closure_var, global_var } variable_class;

enum {
#define BC(name, value) name = value,
#include "bytecodes.h"
#undef BC
  really_not_useful_for_anything_not_a_bytecode
};

/* Max size of unsigned arg1 */
#define ARG1_MAX ((1 << CHAR_BIT) - 1)
/* Maximum for inline constants only, others can be larger */
#define INTEGER1_MAX ((1 << (CHAR_BIT - 1)) - 1)
#define INTEGER1_MIN (-(1 << (CHAR_BIT - 1)))
#define INTEGER2_MAX ((1 << (2 * CHAR_BIT - 1)) - 1)
#define INTEGER2_MIN (-(1 << (2 * CHAR_BIT - 1)))

#define RINSCST(p) (*(value *)(p))
#define WINSCST(p, v) (*(value *)(p) = (v))

#endif
