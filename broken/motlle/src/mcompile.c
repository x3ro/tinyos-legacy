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
	log_error("loop in requires of %s", mod->var);
      else
	warning("failed to load %s", mod->var);
      s->all_loaded = FALSE;
    }
  s->lmodules = new_mlist(s->heap, mod->var, mstatus, s->lmodules);
  s->modules = mod->next;
}

void mprepare_vars(struct mprepare_state *s)
{
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
      u16 n = global_lookup(s->ccontext->gstate, defines->var);
      struct string *omod;
      int ostatus = module_vstatus(s->ccontext->gstate, n, &omod);

      if (!module_vset(s->ccontext->gstate, n, var_module, this_module))
	log_error("cannot define %s: belongs to module %s", defines->var, omod->str);
      else if (ostatus == var_write)
	warning("%s was writable", defines->var);

      definable = new_glist(heap, n, definable);
    }
      
  for (writes = f->writes; writes; writes = writes->next)
    {
      u16 n = global_lookup(s->ccontext->gstate, writes->var);

      if (!module_vset(s->ccontext->gstate, n, var_write, NULL))
	{
	  struct string *belongs;

	  module_vstatus(s->ccontext->gstate, n, &belongs);
	  log_error("cannot write %s: belongs to module %s", writes->var, belongs->str);
	}

      writable = new_glist(heap, n, writable);
    }
      
  for (reads = f->reads; reads; reads = reads->next)
    readable = new_glist(heap, global_lookup(s->ccontext->gstate, reads->var),
			 readable);
}

void mrecall(u16 n, const char *name, fncode fn)
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
	  log_error("read of global %s (module %s)", name, mod->str);
      }
    else if (!all_readable)
      log_error("read of global %s", name);
  }

  ins2(op_recall + global_var, n, fn);
}

void mexecute(u16 n, const char *name, int count, fncode fn)
/* Effects: Generates code to call function in variable n, with count
     arguments
*/
{
  struct string *mod;
  int status = module_vstatus(fnglobals(fn), n, &mod);

  if (!in_glist(n, definable) &&
      !in_glist(n, readable) && !in_glist(n, writable)) {
    if (status == var_module)
      {
	/* Implicitly import protected modules */
	if (module_status(fnglobals(fn), mod->str) != module_protected &&
	    !all_readable && imported(mod->str) == module_unloaded)
	  log_error("read of global %s (module %s)", name, mod->str);
      }
    else if (!all_readable)
      log_error("read of global %s", name);
  }

  if (count == 1)
    ins2(op_execute_global1, n, fn);
  else if (count == 2)
    ins2(op_execute_global2, n, fn);
  else
    {
      /* Could have an op_execute_global */
      ins2(op_recall + global_var, n, fn);
      ins1(op_execute, count, fn);
    }
}

void massign(u16 n, const char *name, fncode fn)
/* Effects: Generate code to assign to variable n
*/
{
  struct string *mod;
  int status = module_vstatus(fnglobals(fn), n, &mod);

  if (status == var_module)
    if (mod == this_module && fntoplevel(fn)) 
      /* defined here */
      ins2(op_define, n, fn);
    else
      log_error("write of global %s (module %s)", name, mod->str);
  else if (all_writable || in_glist(n, writable))
    {
      ins2(op_assign + global_var, n, fn);
      if (status != var_write)
	module_vset(fnglobals(fn), n, var_write, NULL);
    }
  else
    log_error("write of global %s", name);
}

void mcompile_init(void)
{
  staticpro((value *)&this_module);
}
