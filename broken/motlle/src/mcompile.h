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

#ifndef MCOMPILE_H
#define MCOMPILE_H

#include "tree.h"
#include "ins.h"

/* Compile module references */

/* A list of imported modules */
typedef struct _mlist *mlist;

struct mprepare_state
{
  struct compile_context *ccontext;
  mfile f;
  block_t heap;
  bool all_loaded;
  mlist lmodules;
  vlist modules;
};

int mprepare(struct mprepare_state *s, block_t heap, mfile f);
condCC mprepare_load_next_start(struct mprepare_state *s);
void mprepare_load_next_done(struct mprepare_state *s);
void mprepare_vars(struct mprepare_state *s);
/* Effects: Start processing module f:
     - unload f
     - load required modules
     - change status of variables of f (defines, writes)
     - setup information for mrecall/massign/mexecute

     Sends error/warning messages.

     This is a split-phase op (because load/exec is split-phase). You must
     have a persistent pointer to an mprepare_state structure which you
     pass to all phases of the split-phase op. The logical sequence of calls
     must be as below:

     if (mprepare(s, heap, f))
       {
         while (mprepare_load_next_start(s))
	   // SPLIT-POINT
	   mprepare_load_next_done(s);
         mprepare_vars(s);
       }

     SPLIT-POINT is where control must return to the top-level FA_EXECUTE
     dispatcher. While suspended at SPLIT-POINT, runtime errors represent
     errors in the load code.
   Returns: mprepare returns TRUE iff compilation can proceed
*/

void mrecall(u16 n, const char *name, fncode fn);
/* Effects: Generate code to recall variable n
*/

void mexecute(u16 offset, const char *name, int count, fncode fn);
/* Effects: Generates code to call function in variable n, with count
     arguments. If name is NULL, assume that it is part of a protected
     imported module (used for builtins)
*/

void massign(u16 n, const char *name, fncode fn);
/* Effects: Generate code to assign to variable n
*/

void mcompile_init(void);

#endif
