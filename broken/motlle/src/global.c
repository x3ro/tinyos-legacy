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

  GCPRO1(machine);
  gstate = (struct global_state *)allocate_record(type_vector, 5);
  GCPRO1(gstate);
  gstate->modules = alloc_table(DEF_TABLE_SIZE);
  gstate->mvars = alloc_vector(GLOBAL_SIZE);
  gstate->global = alloc_table(GLOBAL_SIZE);
  gstate->environment = alloc_env(GLOBAL_SIZE);
  gstate->machine = machine;
  GCPOP(2);

  return gstate;
}

static u16 global_add(struct global_state *gstate,
		      struct string *name, value val)
{
  struct symbol *pos;
  ivalue old_size, aindex;

  GCCHECK(val);

  GCPRO2(gstate, name);
  old_size = vector_len(gstate->environment->values);
  aindex = env_add_entry(gstate->environment, val);
  if (vector_len(gstate->environment->values) != old_size) /* Increase mvars too */
    {
      struct vector *new_mvars = alloc_vector(vector_len(gstate->environment->values));

      memcpy(new_mvars->data, gstate->mvars->data,
	     gstate->mvars->o.size - sizeof(struct obj));
      gstate->mvars = new_mvars;
    }
  GCPOP(2);
  gstate->mvars->data[aindex] = makeint(var_normal);
  pos = table_add_fast(gstate->global, name, makeint(aindex));
  SET_READONLY(pos); /* index of global vars never changes */

  return aindex;
}

u16 global_lookup(struct global_state *gstate, const char *name)
/* Returns: the index for global variable name in environment.
     If name doesn't exist yet, it is created with a variable
     whose value is NULL.
*/
{
  struct symbol *pos;
  struct string *tname;

  if (table_lookup(gstate->global, name, &pos))
    return (u16)intval(pos->data);

  GCPRO1(gstate);
  tname = alloc_string(name);
  GCPOP(1);

  return global_add(gstate, tname, NULL);
}

u16 mglobal_lookup(struct global_state *gstate, struct string *name)
/* Returns: the index for global variable name in environment.
     If name doesn't exist yet, it is created with a variable
     whose value is NULL.
*/
{
  struct symbol *pos;
  struct string *tname;

  if (table_lookup(gstate->global, name->str, &pos))
    return (u16)intval(pos->data);

  GCPRO2(gstate, name);
  tname = alloc_string_n(string_len(name));
  strcpy(tname->str, name->str);
  GCPOP(2);

  return global_add(gstate, tname, NULL);
}

struct list *global_list(struct global_state *gstate)
/* Returns: List of symbols representing all the global variables.
     The value cell of each symbol contains the variables number
*/
{
  return table_list(gstate->global);
}
