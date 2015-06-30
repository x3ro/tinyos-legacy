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

#include <string.h>
#include "mudlle.h"
#include "global.h"
#include "objenv.h"
#include "table.h"
#include "alloc.h"
#include "types.h"
#include "error.h"
#include "module.h"

struct global_state *new_global_state(struct machine_specification *machine)
/* Returns: A new global state for a motlle interpreter for machine
*/
{
  struct global_state *gstate;
  value tmp;

  GCPRO1(machine);
  gstate = (struct global_state *)allocate_record(type_vector, 8);
  GCPRO1(gstate);
  tmp = alloc_table(DEF_TABLE_SIZE); gstate->modules = tmp;
  tmp = alloc_vector(GLOBAL_SIZE); gstate->mvars = tmp;
  tmp = alloc_vector(GLOBAL_SIZE); gstate->types = tmp;
  tmp = alloc_vector(GLOBAL_SIZE); gstate->names = tmp;
  tmp = alloc_table(GLOBAL_SIZE); gstate->global = tmp;
  tmp = alloc_table(DEF_TABLE_SIZE); gstate->gsymbols = tmp;
  tmp = alloc_env(GLOBAL_SIZE); gstate->environment = tmp;
  gstate->machine = machine;
  GCPOP(2);

  return gstate;
}

struct global_state *copy_global_state(struct global_state *gstate)
/* Returns: A copy of global state gstate, which includes copying
     global variable and module state
*/
{
  struct global_state *newp;
  value tmp;

  GCPRO1(gstate);
  newp = (struct global_state *)allocate_record(type_vector, 8);
  GCPRO1(newp);
  tmp  = copy_table(gstate->modules); newp->modules = tmp;
  tmp  = copy_vector(gstate->mvars); newp->mvars = tmp;
  tmp  = copy_vector(gstate->types); newp->types = tmp;
  tmp  = copy_vector(gstate->names); newp->names = tmp;
  tmp  = copy_table(gstate->global); newp->global = tmp;
  tmp  = copy_table(gstate->gsymbols); newp->gsymbols = tmp;
  tmp  = copy_env(gstate->environment); newp->environment = tmp;
  newp->machine = gstate->machine;
  GCPOP(2);

  return newp;
}

void global_set(struct global_state *g1, struct global_state *g2)
/* Effects: Sets global state g1 to that specified by g2
   Requires: g1 and g2 be for the same machine
 */
{
  assert(g1->machine == g2->machine);
  g1->modules = g2->modules;
  g1->mvars = g2->mvars;
  g1->types = g2->types;
  g1->names = g2->names;
  g1->global = g2->global;
  g1->gsymbols = g2->gsymbols;
  g1->environment = g2->environment;
}

static u16 global_add1(struct global_state *gstate,
		       struct string *name, mtype type, value val)
{
  struct symbol *pos;
  ivalue old_size, aindex;

  GCCHECK(val);

  GCPRO2(gstate, name);
  old_size = vector_len(gstate->environment->values);
  aindex = env_add_entry(gstate->environment, val);
  if (vector_len(gstate->environment->values) != old_size) /* Increase mvars too */
    {
      uvalue newsize = vector_len(gstate->environment->values);
      struct vector *new_mvars, *new_names, *new_types;

      new_mvars = alloc_vector(newsize);
      GCPRO1(new_mvars);
      new_names = alloc_vector(newsize);
      GCPRO1(new_names);
      new_types = alloc_vector(newsize);
      GCPOP(2);
      
      memcpy(new_mvars->data, gstate->mvars->data,
	     gstate->mvars->o.size - sizeof(struct obj));
      gstate->mvars = new_mvars;
      memcpy(new_names->data, gstate->names->data,
	     gstate->names->o.size - sizeof(struct obj)); 
      gstate->names = new_names;
      memcpy(new_types->data, gstate->types->data,
	     gstate->types->o.size - sizeof(struct obj)); 
      gstate->types = new_types;
    }
  GCPOP(2);
  gstate->mvars->data[aindex] = makeint(var_normal);
  gstate->names->data[aindex] = name;
  gstate->types->data[aindex] = makeint(type);
  pos = table_add_fast(gstate->global, name, makeint(aindex));
  SET_READONLY(pos); /* index of global vars never changes */

  return aindex;
}

u16 global_add(struct global_state *gstate, const char *name, mtype t)
/* Effects: adds name to global environment gstate, along with its type (t)
     If variable already exists, change its type to t.
   Returns: the new variable's index
   Modifies: gstate
*/
{
  struct string *tname;
  mtype current_type;
  u16 pos = global_lookup(gstate, name, &current_type);

  if (pos != GLOBAL_INVALID)
    {
      gstate->types->data[pos] = makeint(t);
      return pos;
    }

  GCPRO1(gstate);
  tname = alloc_string(name);
  GCPOP(1);

  return global_add1(gstate, tname, t, NULL);
}

u16 global_lookup(struct global_state *gstate, const char *name, mtype *t)
/* Returns: the index for global variable name in environment.
     If name doesn't exist yet, returns GLOBAL_INVALID
     Also sets *t to its type
*/
{
  struct symbol *pos;

  if (table_lookup(gstate->global, name, &pos))
    {
      u16 offset = (u16)intval(pos->data);
      *t = intval(gstate->types->data[offset]);
      return offset;
    }

  return GLOBAL_INVALID;
}

u16 mglobal_lookup(struct global_state *gstate, struct string *name)
/* Returns: the index for global variable name in environment.
     If name doesn't exist yet, returns GLOBAL_INVALID
*/
{
  mtype t;

  return global_lookup(gstate, name->str, &t);
}

struct list *global_list(struct global_state *gstate)
/* Returns: List of symbols representing all the global variables.
     The value cell of each symbol contains the variables number
*/
{
  return table_list(gstate->global);
}
