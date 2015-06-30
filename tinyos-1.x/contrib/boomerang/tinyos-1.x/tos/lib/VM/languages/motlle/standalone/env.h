/*
 * Copyright (c) 1993-1999 David Gay and Gustav H�llberg
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

#ifndef ENV_H
#define ENV_H

#include "tree.h"
#include "code.h"
#include "ins.h"

/* if you change this, make sure to fix the lexer too */
#define GLOBAL_ENV_PREFIX ":"

typedef struct _varlist
{
  struct _varlist *next;
  variable_class vclass;
  u16 offset;
} *varlist;

void env_reset(void);
/* Effects: Clears the environment stack
*/

void env_push(vlist locals, fncode fn);
/* Effects: Starts a new environment (for a new function), with local
     variables 'locals' in function 'fn'.
*/

void env_block_push(vlist locals);
/* Effects: We have entered a local scope of the environment at the top
     of the stack. Add locals to the list of variables for this scope,
     and initialise them to null if necessary.
*/

void env_declare(vlist locals);
/* Effects: declare variables in locals. toplevel is TRUE if this
     declaration is at the toplevel (note that the declarations may
     still be local if we are inside a block)
*/

void env_block_pop(void);
/* Effects: Pop a local scope
*/

varlist env_pop(u8 *nb_locals);
/* Effects: Pop an environement, returning the variables that it needs
     it it's closure as well as the number of local variables it uses.
*/

variable_class env_lookup(location l, const char *name, u16 *offset, mtype *type,
			  bool implicit);
/* Effects: Returns the class & offset of variable name for the current
     environment. Modifies the closures appropriately.
     *type is set to the variable's type ([s]type_xxx)
     If implicit is true, implicitly declare a global variable called
     name if none exists.
*/

#endif
