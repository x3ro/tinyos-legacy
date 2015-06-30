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
#include "tree.h"
#include "env.h"
#include "ins.h"
#include "global.h"
#include "compile.h"

struct locals_list
{
  struct locals_list *next;
  u16 index;
  vlist locals;
  bool implicit, parms;
};

struct env_stack
{
  fncode fn;
  struct env_stack *next, *prev;
  struct locals_list *locals;
  u16 size, max_size;		/* Current & max length of locals */
  varlist closure;
};

static struct env_stack *env_stack;

static varlist new_varlist(block_t heap, variable_class vclass,
			   u16 offset, varlist next)
{
  varlist newp = allocate(heap, sizeof *newp);

  newp->next = next;
  newp->vclass = vclass;
  newp->offset = offset;

  return newp;
}

static struct locals_list *new_locals_list(block_t heap, vlist vars, u16 idx,
					   bool implicit, bool parms,
					   struct locals_list *next)
{
  struct locals_list *newp = allocate(heap, sizeof *newp);

  newp->next = next;
  newp->index = idx;
  newp->locals = vars;
  newp->implicit = implicit;
  newp->parms = parms;

  return newp;
}

u16 vlist_length(vlist scan)
{
  u16 nlocals = 0;

  for (; scan; scan = scan->next) nlocals++;

  return nlocals;
}

void env_reset(void)
{
  env_stack = NULL;
}

static bool env_inblock(void)
{
  return env_stack->locals && !env_stack->locals->parms;
}

static void env_pop_locals(void)
{
  /* Cannot share variables as some of them may escape */
  /* Think about this (most variables can be shared, and the
     variable cells always can be) */
  /*env_stack->size -= vlist_length(env_stack->locals->locals);*/
  env_stack->locals = env_stack->locals->next;
}

static void env_pop_all_implicit(void)
{
  while (env_stack->locals && env_stack->locals->implicit)
    env_pop_locals();
}

static struct locals_list *block_start(void)
{
  struct locals_list *l = env_stack->locals;

  while (l && l->implicit)
    l = l->next;

  return l;
}

static void check_duplicates_in(struct locals_list *upto, vlist check)
/* Effects: Report an error if there is any declaration of `check'
     in declarations from the top locals list (up to, but not including
     check itself), up to (and including) the locals list `upto'
*/
{
  struct locals_list *l = env_stack->locals;
  vlist v, last = check;

  for (;;)
    {
      for (v = l->locals; v != last; v = v->next)
	if (strcmp(v->var, check->var) == 0)
	  {
	    log_error(v->l, "redeclaration of `%s'", check->var);
	    return;
	  }
      if (l == upto)
	return;
      l = l->next;
      last = NULL;
    }
}

static void check_duplicate_decls(void)
/* Effects: Report an error if the latest declarations include duplicate
     declarations (amongst themselves or earlier declarations in the
     same block)
*/
{
  vlist tocheck;
  struct locals_list *blk = block_start();

  for (tocheck = env_stack->locals->locals; tocheck; tocheck = tocheck->next)
    check_duplicates_in(blk, tocheck);
}

static void declare_locals(vlist locals, bool implicit, bool parms)
{
  u16 nsize;
  struct locals_list *old_locals = env_stack->locals;

  /* Add locals */
  env_stack->locals = new_locals_list(fnmemory(env_stack->fn), locals,
				      env_stack->size, implicit, parms,
				      env_stack->locals);
  check_duplicate_decls();

  /* Update size info, clears vars if necessary */
  nsize = env_stack->size + vlist_length(locals);
  if (env_stack->max_size < nsize)
    env_stack->max_size = nsize;
  env_stack->size = nsize;
}

void env_push(vlist parms, fncode fn)
{
  struct env_stack *newp = allocate(fnmemory(fn), sizeof *newp);

  newp->fn = fn;
  newp->next = env_stack;
  newp->prev = NULL;
  newp->size = newp->max_size = 0;
  newp->locals = NULL;
  newp->closure = NULL;
  if (env_stack) env_stack->prev = newp;
  env_stack = newp;

  declare_locals(parms, FALSE, TRUE);
}

varlist env_pop(u8 *nb_locals)
{
  varlist closure = env_stack->closure;

  *nb_locals = env_stack->max_size;
  env_stack = env_stack->next;
  if (env_stack) env_stack->prev = NULL;
  return closure;
}

static void env_push_locals(vlist locals, bool implicit, bool inloop)
{
  u16 osize = env_stack->size, i;

  declare_locals(locals, implicit, FALSE);
  /* TODO: only clear if no init */
  if (inloop)
    for (i = osize; i < env_stack->size; i++)
      ins1(OPmclearl, i, env_stack->fn);
}

void env_block_push(vlist locals, bool inloop)
{
  env_push_locals(locals, FALSE, inloop);
}

void env_declare(vlist locals, bool toplevel, bool inloop)
{
  if (toplevel && !env_inblock())
    for (;locals; locals = locals->next)
      {
	struct global_state *gstate = fnglobals(env_stack->fn);
	mtype current_type;
	u16 offset = global_lookup(gstate, locals->var, &current_type);

	if (offset != GLOBAL_INVALID)
	  if (locals->type != current_type && current_type != itype_implicit)
	    warning(locals->l, "redeclaring global `%s' with incompatible type",
		  locals->var);
	/* global_add will just update the type for existing vars. */
	offset = global_add(gstate, locals->var, locals->type);
      }
  else
    env_push_locals(locals, TRUE, inloop);
}

void env_block_pop(void)
{
  env_pop_all_implicit();
  env_pop_locals();
}

static variable_class env_close(struct env_stack *env, u16 pos, u16 *offset)
/* Effects: Adds local variable pos of environment env to all closures
     below it in the env_stack.
   Returns: local_var if env is the last environment on the stack,
     closure_var otherwise.
     *offset is the offset in the closure or local variables at which
     the local variable <env,pos> can be found by the function whose
     environement is env_stack.
*/
{
  struct env_stack *subenv;
  variable_class vclass = local_var;

  /* Add <env,pos> to all environments below env */
  for (subenv = env->prev; subenv; subenv = subenv->prev)
    {
      varlist *closure;
      u16 coffset;
      int found = FALSE;

      /* Is <class,pos> already in closure ? */
      for (coffset = 0, closure = &subenv->closure; *closure;
	   coffset++, closure = &(*closure)->next)
	if (vclass == (*closure)->vclass && pos == (*closure)->offset) /* Yes ! */
	  {
	    found = TRUE;
	    break;
	  }
      if (!found)
	/* Add variable to closure, at end */
	*closure = new_varlist(fnmemory(subenv->fn), vclass, pos, NULL);

      /* Copy reference to this closure position into <class,pos> */
      /* This is how the variable will be named in the next closure */
      vclass = closure_var;
      pos = coffset;
    }
  *offset = pos;
  return vclass;
}

variable_class env_lookup(location l, const char *name, u16 *offset, mtype *type,
			  bool implicit)
{
  struct env_stack *env;

  if (strncasecmp(name, GLOBAL_ENV_PREFIX, strlen(GLOBAL_ENV_PREFIX)) == 0)
    name += strlen(GLOBAL_ENV_PREFIX);
  else
    for (env = env_stack; env; env = env->next)
      {
	/* Look for variable in environment env */
	vlist vars;
	struct locals_list *scope;
	u16 pos;
	
	for (scope = env->locals; scope; scope = scope->next)
	  for (pos = scope->index, vars = scope->locals; vars; pos++, vars = vars->next)
	    if (strcmp(name, vars->var) == 0)
	      {
		*type = vars->type;
		return env_close(env, pos, offset);
	      }
      }
  
  /* Not found, is global */
  *type = stype_any; /* ensure type is a legal value */
  *offset = global_lookup(fnglobals(env_stack->fn), name, type);

  /* Implicit declaration handling */
  if (*offset == GLOBAL_INVALID)
    {
      if (implicit)
	{
	  *offset = global_add(fnglobals(env_stack->fn), name, itype_implicit);
	  assert(*offset != GLOBAL_INVALID);
	}
    }
  else if (*type == itype_implicit)
    {
      /* implicitly declared globals can only be used in contexts which
	 would cause implicit declaration */
      if (implicit)
	*type = stype_any;
      else
	*offset = GLOBAL_INVALID;
    }

  if (*offset == GLOBAL_INVALID)
    log_error(l, "global variable `%s' undeclared", name);

  return global_var;
}
