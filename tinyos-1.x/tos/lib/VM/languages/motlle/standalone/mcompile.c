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

#include "mudlle.h"
#include "tree.h"
#include "types.h"
#include "code.h"
#include "ins.h"
#include "global.h"
#include "calloc.h"
#include "compile.h"
#include "module.h"
#include "mcompile.h"
#include "primitives.h"

#include <string.h>
#include <stdlib.h>

/* A list of global variable indexes */
typedef struct _glist {
  struct _glist *next;
  u16 n;
} *glist;

static glist new_glist(block_t heap, u16 n, glist next)
{
  glist newp = allocate(heap, sizeof *newp);

  newp->next = next;
  newp->n = n;

  return newp;
}

static int in_glist(u16 n, glist l)
{
  for (; l; l = l->next)
    if (n == l->n) return TRUE;

  return FALSE;
}

static glist readable;
static int all_readable;
static glist writable;
static int all_writable;
static glist definable;
static struct string *this_module;

/* A list of imported modules */
struct _mlist { 
  struct _mlist *next;
  const char *name;
  int status;
};

static mlist imported_modules;

static mlist new_mlist(block_t heap, const char *name, int status, mlist next)
{
  mlist newp = allocate(heap, sizeof *newp);

  newp->next = next;
  newp->name = name;
  newp->status = status;

  return newp;
}

static int imported(const char *name)
/* Returns: status of name in imported_modules, module_unloaded if absent
*/
{
  mlist mods;

  for (mods = imported_modules; mods; mods = mods->next)
    if (stricmp(mods->name, name) == 0) return mods->status;

  return module_unloaded;
}

/* Split phase programming is SO much fun. */

int mprepare(struct mprepare_state *s, block_t heap, mfile f)
/* Effects: Start processing module f:
     - unload f
     - load required modules
     - change status of variables of f (defines, writes)
     - setup information for mrecall/massign/mexecute

     Sends error/warning messages.
   Returns: TRUE if compilation can proceed
*/
{
  if (f->name)
    {
      if (!module_unload(s->ccontext->gstate, f->name))
	return FALSE;
      module_set(s->ccontext->gstate, f->name, module_loading);
    }

  s->f = f;
  s->heap = heap;
  s->all_loaded = TRUE;
  s->lmodules = NULL;
  s->modules = f->imports;

  return TRUE;
}

condCC mprepare_load_next_start(struct mprepare_state *s)
{
  vlist mod = s->modules;

  /* Load next module */
  if (!mod)
    return FALSE;

  module_require(s->ccontext, mod->var);
  return TRUE;
}

void mprepare_load_next_done(struct mprepare_state *s)
{
  vlist mod = s->modules;
  int mstatus = module_status(s->ccontext->gstate, mod->var);

  stack_pop();

  if (mstatus < module_loaded)
    {
      if (mstatus == module_loading)
	log_error(mod->l, "loop in requires of %s", mod->var);
      else
	warning(mod->l, "failed to load %s", mod->var);
      s->all_loaded = FALSE;
    }
  s->lmodules = new_mlist(s->heap, mod->var, mstatus, s->lmodules);
  s->modules = mod->next;
}

void mprepare_vars(struct mprepare_state *s)
{
  mtype t;
  mfile f = s->f;
  block_t heap = s->heap;
  vlist reads, writes, defines;

  imported_modules = s->lmodules;

  all_writable = f->vclass == f_plain;
  all_readable = f->vclass == f_plain || !s->all_loaded;
  readable = writable = definable = NULL;
  if (f->name) 
    {
      this_module = alloc_string(f->name);
      SET_READONLY(this_module);
    }
  else
    this_module = NULL;

  /* Change status of variables */
  for (defines = f->defines; defines; defines = defines->next)
    {
      u16 n = global_lookup(s->ccontext->gstate, defines->var, &t);
      struct string *omod;
      int ostatus = module_vstatus(s->ccontext->gstate, n, &omod);

      if (!module_vset(s->ccontext->gstate, n, var_module, this_module))
	log_error(defines->l, "cannot define %s: belongs to module %s", defines->var, omod->str);
      else if (ostatus == var_write)
	warning(defines->l, "%s was writable", defines->var);

      definable = new_glist(heap, n, definable);
    }
      
  for (writes = f->writes; writes; writes = writes->next)
    {
      u16 n = global_lookup(s->ccontext->gstate, writes->var, &t);

      if (!module_vset(s->ccontext->gstate, n, var_write, NULL))
	{
	  struct string *belongs;

	  module_vstatus(s->ccontext->gstate, n, &belongs);
	  log_error(writes->l, "cannot write %s: belongs to module %s", writes->var, belongs->str);
	}

      writable = new_glist(heap, n, writable);
    }
      
  for (reads = f->reads; reads; reads = reads->next)
    readable = new_glist(heap, global_lookup(s->ccontext->gstate, reads->var, &t),
			 readable);
}

void mrecall(location l, u16 n, const char *name, fncode fn)
/* Effects: Generate code to recall variable n
*/
{
  struct string *mod;
  struct global_state *gstate = fnglobals(fn);
  int status = module_vstatus(gstate, n, &mod);

  if (!in_glist(n, definable) &&
      !in_glist(n, readable) && !in_glist(n, writable)) {
    if (status == var_module)
      {
	/* Implicitly import protected modules */
	if (module_status(gstate, mod->str) == module_protected)
	  {
	    if (immutablep(GVAR(gstate, n))) /* Use value */
	      {
		ins_constant(GVAR(gstate, n), fn);
		return;
	      }
	  }
	else if (!all_readable && imported(mod->str) == module_unloaded)
	  log_error(l, "read of global %s (module %s)", name, mod->str);
      }
    else if (!all_readable)
      log_error(l, "read of global %s", name);
  }

  ins2(OPmreadg, n, fn);
}

void mexecute(location l, u16 n, const char *name, int count, fncode fn)
/* Effects: Generates code to call function in variable n, with count
     arguments
*/
{
  struct string *mod;
  struct global_state *gstate = fnglobals(fn);
  int status = module_vstatus(gstate, n, &mod);
  bool protectedvar = FALSE;
  value gval = 0;

  if (!in_glist(n, definable) &&
      !in_glist(n, readable) && !in_glist(n, writable)) {
    if (status == var_module)
      {
	int mstatus = module_status(gstate, mod->str);

	if (mstatus == module_protected)
	  {
	    gval = GVAR(gstate, n);
	    protectedvar = TRUE;
	    /* call primitives directly if args correct */
	    if (PRIMITIVEP(gval))
	      {
		int nargs = PRIMOP(gstate, gval)->nargs;
		int nb = ATOM_TO_PRIMITIVE_NB(gval);

		if (nargs == count && nb < 64)
		  {
		    insprim(OPmexecprim6 + nb, nargs, fn);
		    return;
		  }
	      }
	  }

	/* Implicitly import protected modules */
	if (mstatus != module_protected &&
	    !all_readable && imported(mod->str) == module_unloaded)
	  log_error(l, "read of global %s (module %s)", name, mod->str);
      }
    else if (!all_readable)
      log_error(l, "read of global %s", name);
  }

  if (protectedvar)
    {
      /* Use the value so as to avoid the need for a variable slot */
      ins_constant(gval, fn);
      ins0(OPmexec4 + (count & 0xf), fn);
    }
  else
    ins2(OPmexecg4 + (count & 0xf), n, fn);
}

void massign(location l, u16 n, const char *name, fncode fn)
/* Effects: Generate code to assign to variable n
*/
{
  struct string *mod;
  int status = module_vstatus(fnglobals(fn), n, &mod);

  if (status == var_module)
    if (mod == this_module && fntoplevel(fn)) 
      /* defined here */
      ins2(OPmwriteg, n, fn);
    else
      log_error(l, "write of global %s (module %s)", name, mod->str);
  else if (all_writable || in_glist(n, writable))
    {
      ins2(OPmwriteg, n, fn);
      if (status != var_write)
	module_vset(fnglobals(fn), n, var_write, NULL);
    }
  else
    log_error(l, "write of global %s", name);
}

void mcompile_init(void)
{
  staticpro((value *)&this_module);
}
