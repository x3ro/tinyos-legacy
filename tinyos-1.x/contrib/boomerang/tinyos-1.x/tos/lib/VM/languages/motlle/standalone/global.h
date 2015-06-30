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

#ifndef GLOBAL_H
#define GLOBAL_H

#include "mvalues.h"
#include "machine.h"

struct global_state		/* Is a record (vector) */
{
  struct obj o;
  struct table *modules;	/* Known modules */
  struct vector *mvars;		/* module-state for each variable */
  struct vector *names;		/* name of each variable */
  struct vector *types;		/* type of each variable (itype_implicit
				   for implicitly declared ones) */
  struct table *global;		/* Known global variables */
  struct table *gsymbols;	/* Global (scheme) symbols */
  struct env *environment;	/* Values of global variables */
  struct machine_specification *machine;
};

#define GLOBAL_INVALID 0xffff

#ifdef STANDALONE
extern struct vector *env_values;
extern struct primitive_ext *primops[];

#define PRIMOP(gstate, p) (primops[ATOM_TO_PRIMITIVE_NB((p))])

#define GVAR(gstate, offset) (env_values->data[(offset)])
/* Returns: The global value at 'offset'
*/

#define GCONSTANT(gstate, offset) 0
/* Returns: a true value if global variable offset is not modifiable
     (ie is a 'define' of some module)
*/

#else

#define PRIMOP(gstate, p) (C_MACHINE_SPECIFICATION(gstate->machine)->primops[ATOM_TO_PRIMITIVE_NB((p))])

/* The global_state for the machine motlle is running on */
extern struct global_state *globals;

#include "objenv.h"

u16 global_add(struct global_state *gstate, const char *name, mtype t);
/* Effects: adds name to global environment gstate, along with its type (t)
   Returns: the new variable's index, or GLOBAL_INVALID if the variable
     already exists
   Modifies: gstate
*/

u16 global_lookup(struct global_state *gstate, const char *name, mtype *t);
/* Returns: the index for global variable name in environment.
     If name doesn't exist yet, returns GLOBAL_INVALID
     Also sets *t to its type (variables of type itype_implicit are
     returned as stype_any)
*/

u16 mglobal_lookup(struct global_state *gstate, struct string *name);
/* Returns: the index for global variable name in environment.
     If name doesn't exist yet, returns GLOBAL_INVALID
*/

struct global_state *new_global_state(struct machine_specification *machine);
/* Returns: A new global state for a motlle interpreter for machine
*/

struct global_state *copy_global_state(struct global_state *gstate);
/* Returns: A copy of global state gstate, which includes copying
     global variable and module state
*/

void global_set(struct global_state *g1, struct global_state *g2);
/* Effects: Sets global state g1 to that specified by g2
   Requires: g1 and g2 be for the same machine
 */

struct list *global_list(struct global_state *gstate);
/* Returns: List of symbols representing all the global variables.
     The value cell of each symbol contains the variables number
*/

#define GVAR(gstate, offset) (gstate->environment->values->data[(offset)])
/* Returns: The global value at 'offset'
*/

#define GCONSTANT(gstate, offset) (!INTEGERP(gstate->mvars->data[(offset)]))
/* Returns: a true value if global variable offset is not modifiable
     (ie is a 'define' of some module)
*/

#endif

#endif
