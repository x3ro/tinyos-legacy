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
#include <stdlib.h>
#include "mudlle.h"
#include "table.h"
#include "global.h"
#include "alloc.h"
#include "module.h"
#include "call.h"

/* Module states automaton:

            -> unloaded	<-
           /      |       \
	   |      |	   \
	   |   loading	   |
	   |    /   \ 	   |
	   \   /     \	  /
	    error   loaded
	              |
	              |
	          protected

*/

int module_status(struct global_state *gstate, const char *name)
/* Returns: Status of module name:
     module_unloaded: module has never been loaded, or has been unloaded
     module_loaded: module loaded successfully
     module_error: attempt to load module led to error
*/
{
  struct symbol *sym;

  if (!table_lookup(gstate->modules, name, &sym))
    return module_unloaded;
  return intval(sym->data);
}

void module_set(struct global_state *gstate, const char *name, int status)
/* Effects: Sets module status
*/
{
  table_set(gstate->modules, name, makeint(status));
}

int module_unload(struct global_state *gstate, const char *name)
/* Effects: Removes all knowledge about module 'name' (eg prior to reloading it)
     module_status(name) will return module_unloaded if this operation is
     successful
     Sets to null all variables that belonged to name, and resets their status
     to var_normal
   Returns: FALSE if name was protected or loading
*/
{
  int status = module_status(gstate, name);

  if (status != module_unloaded)
    {
      ivalue gsize = intval(gstate->environment->used), i;

      if (status == module_loading || status == module_protected) return FALSE;

      for (i = 0; i < gsize; i++)
	{
	  struct string *v = gstate->mvars->data[i];

	  /* Unset module vars */
	  if (!INTEGERP(v) && stricmp(name, v->str) == 0)
	    {
	      gstate->mvars->data[i] = makeint(var_normal);
	      GVAR(gstate, i) = NULL;
	    }
	}
      /* Safe even if name comes from a mudlle string,
	 because we know that entry name already exists */
      module_set(gstate, name, module_unloaded);
    }

  return TRUE;
}

void module_load(struct compile_context *ccontext, const char *name)
/* Effects: Attempts to load module name by calling mudlle hook
     Error/warning messages are sent to muderr
     Sets erred to TRUE in case of error
     Updates module status
   Modifies: erred
   Requires: module_status(name) == module_unloaded
*/
{
  GCPRO1(ccontext);
  stack_reserve(2 * sizeof(value));
  stack_push(ccontext);
  stack_push(alloc_string(name));
  setup_call_stack(ccontext->gstate->machine->library_installer, 2);
  GCPOP(1);
}

void module_require(struct compile_context *ccontext, const char *name)
/* Effects: Does module_load(name) if module_status(name) == module_unloaded
     Other effects as in module_load
*/
{
  if (module_status(ccontext->gstate, name) == module_unloaded)
    module_load(ccontext, name);
  else
    {
      /* load will leave one value on the stack. do the same */
      stack_reserve(sizeof(value));
      stack_push(makeint(0));
    }
}

int module_vstatus(struct global_state *gstate, u16 n, struct string **name)
/* Returns: status of global variable n:
     var_normal: normal global variable, no writes
     var_write: global variable which is written
     var_module: defined symbol of a module
       module name is stored in *name
   Modifies: name
   Requires: n be a valid global variable offset
*/
{
  struct string *v;

  if (n == GLOBAL_INVALID)
    return var_write;

  v = gstate->mvars->data[n];

  if (INTEGERP(v)) return intval(v);

  *name = v;
  return var_module;
}

int module_vset(struct global_state *gstate, u16 n, int status, struct string *name)
/* Effects: Sets status of global variable n to status.
     name is the module name for status var_module
   Returns: TRUE if successful, FALSE if the change is impossible
     (ie status was already var_module)
*/
{
  if (n == GLOBAL_INVALID)
    return TRUE;

  if (!INTEGERP(gstate->mvars->data[n])) return FALSE;

  if (status == var_module)
    gstate->mvars->data[n] = name;
  else
    gstate->mvars->data[n] = makeint(status);

  return TRUE;
}
