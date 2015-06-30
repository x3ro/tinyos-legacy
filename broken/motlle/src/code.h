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
  /* Simple operations */
  op_return,			/* arg0 */
  op_constant,			/* constant follows */
  op_integer1,			/* arg1 is signed integer */
  op_closure,			/* arg1 is # of closure variables,
				   followed by the arg1 closure vars, encoded
				   as (var #) << 1 + (variable_class)
				   followed by the code constant for this
				   closure */
  op_execute,			/* arg1 is # of parameters passed */
  op_execute_global1,		/* arg2 is global offset */
  op_execute_global2,		/* arg2 is global offset */
  op_discard,			/* arg0. Pop top of stack (discard result) */
  op_exit_n,			/* arg1. Pop top of stack, pop n entries, push old top of stack */
  /* All branch instructions must be consecutive, with the 1 byte version
     immediately preceding the 2 byte one.
     op_branch1 must be the first branch */
  op_branch1,			/* arg1 is signed offset from next instruction */
  op_branch2,			/* arg2 is signed offset from next instruction */
  op_loop1,			/* arg1 is signed offset from next instruction */
  op_loop2,			/* arg2 is signed offset from next instruction */
  op_branch_nz1,		/* arg1 is signed offset from next instruction */
  op_branch_nz2,		/* arg2 is signed offset from next instruction */
  op_branch_z1,			/* arg1 is signed offset from next instruction */
  op_branch_z2,			/* arg2 is signed offset from next instruction */

  op_clear_local,		/* arg1 is # of local variable to set to null */
  /* variable operations, which come in local_var, closure_var, global_var
     flavours, and take an arg1 (local, closure) or arg2 (global) indicating the
     offset in the corresponding variable list */
  op_recall,
  op_assign = op_recall + global_var + 1,
  op_define = op_assign + global_var + 1, /* arg2 is # of global variable */

  /* Builtin operations (very common) */
  op_first_builtin,
  op_builtin_eq = op_first_builtin,
  op_builtin_neq,

  op_first_twoint_args,
  op_builtin_gt = op_first_twoint_args,
  op_builtin_lt,
  op_builtin_le,
  op_builtin_ge,
  op_builtin_sub,
  op_builtin_multiply,
  op_builtin_divide,
  op_builtin_remainder,
  op_builtin_bitor,
  op_builtin_bitxor,
  op_builtin_bitand,
  op_builtin_shift_left,
  op_builtin_shift_right,
  op_last_twoint_args = op_builtin_shift_right,

  op_builtin_ref,
  op_builtin_set,
  op_builtin_add,
  op_builtin_negate,
  op_builtin_bitnot,
  op_builtin_not,
  op_builtin_or,
  op_builtin_and,

  op_typecheck			/* typecheck i: op_typecheck + i
				   arg1 is stack offset */
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
