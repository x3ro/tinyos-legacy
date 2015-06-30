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

#include "runtime/runtime.h"
#include "module.h"
#include "vector.h"
#include "basic.h"
#include "symbol.h"
#include "stringops.h"
#include "files.h"
#include "arith.h"
#include "io.h"
#include "list.h"
#include "support.h"
#include "bitset.h"
#include "debug.h"
#include "mote.h"

#include <string.h>
#include <stdlib.h>

static struct string *system_module;
static struct global_state *current_state;

void system_define(const char *name, value val)
/* Modifies: environment
   Requires: name not already exist in environment.
   Effects: Adds name to environment, with value val for the variable,
     as a 'define' of the system module.
*/
{
  u16 aindex;

  GCPRO1(val);
  aindex = global_lookup(current_state, name); /* may allocate ... */
  GCPOP(1);

  GVAR(current_state, aindex) = val;
  module_vset(current_state, aindex, var_module, system_module);
}

void define_string_vector(const char *name, const char **vec, int count)
{
  struct vector *v;
  int n;

  if (count < 0)
    for (count = 0; strcmp(vec[count], "\n") != 0; ++count)
      ;

  v = alloc_vector(count);
  GCPRO1(v);

  for (n = 0; n < count; ++n)
    {
      struct string *s = alloc_string(vec[n]);
      SET_READONLY(s);
      v->data[n] = s;
    }
  GCPOP(1);
  SET_READONLY(v);
  system_define(name, v);
}

void runtime_init(void)
{
  system_module = alloc_string("system");
  staticpro((value *)&system_module);
  staticpro((value *)&current_state);
}

void runtime_setup(struct global_state *gstate)
{
  uvalue i;
  struct c_machine_specification *cms =
    C_MACHINE_SPECIFICATION(gstate->machine);

  current_state = gstate;

  for (i = 0; i < cms->primop_count; i++)
    system_define(cms->primops[i]->name, PRIMITIVE_NB_TO_ATOM(i));

  for (i = 0; i < cms->initialiser_count; i++)
    cms->globals_initialiser[i]();

  module_set(current_state, "system", module_protected);

  current_state = NULL;
}
