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
#include "alloc.h"
#include "types.h"
#include "code.h"
#include "ins.h"
#include "env.h"
#include "global.h"
#include "valuelist.h"
#include "calloc.h"
#include "runtime/runtime.h"
#include "utils.h"
#include "module.h"
#include "mcompile.h"
#include "compile.h"
#include "mparser.h"
#include "call.h"
#include "table.h"
#include "interpret.h"
#include "lexer.h"
#include "scompile.h"
#include "scheme.h"

#include <string.h>
#include <stdlib.h>

int debug_lvl;

static const char *builtin_functions[last_builtin];
instruction builtin_ops[last_builtin];
component component_undefined, component_true, component_false;

static struct string *last_filename;
static const char *last_c_filename;

struct string *make_filename(const char *fname)
{
  if (strcmp(fname, last_c_filename))
    {
      free((void *)last_c_filename);
      last_c_filename = xstrdup(fname);
      last_filename = alloc_string(fname);
      SET_READONLY(last_filename);
    }
  return last_filename;
}

int erred;

void prt_location(location l)
{
  if (l.filename)
    mprintf(muderr, "%s:", l.filename);
  if (l.lineno)
    mprintf(muderr, "%d:", l.lineno);
}

void log_error(location l, const char *msg, ...)
{
  va_list args;
  char err[4096];

  prt_location(l);
  va_start(args, msg);
  vsprintf(err, msg, args);
  va_end(args);
  if (mudout) mflush(mudout);
  mprintf(muderr, "%s" EOL, err);
  if (muderr) mflush(muderr);
  erred = 1;
}

void warning(location l, const char *msg, ...)
{
  va_list args;
  char err[4096];

  prt_location(l);
  va_start(args, msg);
  vsprintf(err, msg, args);
  va_end(args);
  if (mudout) mflush(mudout);
  mprintf(muderr, "warning: %s" EOL, err);
  if (muderr) mflush(muderr);
}

value make_constant(constant c, bool save_location, fncode fn);

static value make_location(location *loc)
{
  return alloc_extptr(loc);
}

static value make_list(constant loc, cstlist csts, int has_tail, bool save_location, fncode fn)
{
  struct list *l;

  if (has_tail && csts != NULL)
    {
      l = csts->cst ? make_constant(csts->cst, FALSE, fn) : NULL;
      csts = csts->next;
    }
  else
    l = NULL;

  GCPRO1(l);
  /* Remember that csts is in reverse order ... */
  while (csts)
    {
      value tmp = make_constant(csts->cst, save_location, fn);

      l = alloc_list(tmp, l);
      SET_READONLY(l); SET_IMMUTABLE(l);
      csts = csts->next;
    }
  if (save_location)
    {
      value vloc = make_location(&loc->loc);
      l = alloc_list(vloc, l);
      SET_READONLY(l); SET_IMMUTABLE(l);
    }
  GCPOP(1);

  return l;
}

static value make_array(cstlist csts, fncode fn)
{
  struct list *l;
  struct vector *v;
  uvalue size = 0, i;
  cstlist scan;
  
  for (scan = csts; scan; scan = scan->next) size++;

  /* This intermediate step is necessary as v is IMMUTABLE
     (so must be allocated after its contents) */
  l = make_list(NULL, csts, 0, FALSE, fn);
  GCPRO1(l);
  v = alloc_vector(size);
  SET_IMMUTABLE(v); SET_READONLY(v);
  GCPOP(1);

  for (i = 0; i < size; i++, l = l->cdr) v->data[i] = l->car;

  return v;
}

static void protect_symbol(struct symbol *s)
{
  SET_READONLY(v);
}

static value make_table(cstlist csts, fncode fn)
{
  struct table *t = alloc_table(DEF_TABLE_SIZE);
  
  GCPRO1(t);
  for (; csts; csts = csts->next)
    table_set(t, csts->cst->u.constpair->cst1->u.string,
	      make_constant(csts->cst->u.constpair->cst2, FALSE, fn), NULL);
  table_foreach(t, protect_symbol);
  SET_READONLY(t);
  GCPOP(1);

  return t;
}

static value make_symbol(cstpair p, fncode fn)
{
  struct symbol *sym;
  struct string *s = alloc_string(p->cst1->u.string);
 
  GCPRO1(s);
  SET_IMMUTABLE(s); SET_READONLY(s);
  sym = alloc_symbol(s, make_constant(p->cst2, FALSE, fn));
  SET_IMMUTABLE(sym); SET_READONLY(sym);
  GCPOP(1);

  return sym;
}

static value make_gsymbol(const char *name, fncode fn)
{
  struct table *gsymbols = (fn ? fnglobals(fn) : globals)->gsymbols;
  struct symbol *gsym;

  if (!table_lookup(gsymbols, name, &gsym)) 
    {
      struct string *s;

      GCPRO1(gsymbols);
      s = alloc_string(name);
      SET_READONLY(s);
      GCPOP(1);
      gsym = table_add_fast(gsymbols, s, makeint(table_entries(gsymbols)));
    }
  return gsym;
}

static value make_quote(constant c, bool save_location, fncode fn)
{
  struct list *l;
  value quote;

  l = alloc_list(make_constant(c->u.constant, save_location, fn), NULL);
  SET_READONLY(l); SET_IMMUTABLE(l);
  GCPRO1(l);
  quote = make_gsymbol("quote", fn);
  l = alloc_list(quote, l);
  SET_READONLY(l); SET_IMMUTABLE(l);
  if (save_location)
    {
      value loc = make_location(&c->loc);
      l = alloc_list(loc, l);
      SET_READONLY(l); SET_IMMUTABLE(l);
    }
  GCPOP(1);

  return l;
}

value make_constant(constant c, bool save_location, fncode fn)
{
  struct obj *cst;

  switch (c->vclass)
    {
    case cst_string:
      cst = (value)alloc_string(c->u.string);
      SET_READONLY(cst); SET_IMMUTABLE(cst);
      return cst;
    case cst_gsymbol: return make_gsymbol(c->u.string, fn);
    case cst_quote: return make_quote(c, save_location, fn);
    case cst_list: return make_list(c, c->u.constants, 1, save_location, fn);
    case cst_array: return make_array(c->u.constants, fn);
    case cst_int: return makeint(c->u.integer);
    case cst_float: return alloc_mudlle_float(c->u.mudlle_float);
    case cst_table: return make_table(c->u.constants, fn);
    case cst_symbol: return make_symbol(c->u.constpair, fn);
    default:
      abort();
    }
}

typedef void (*gencode)(void *data, fncode fn);

void generate_function(function f, fncode fn);
void generate_component(component comp, const char *mlabel, bool discard, fncode fn);
void generate_condition(component condition,
			label slab, gencode scode, void *sdata,
			label flab, gencode fcode, void *fdata,
			fncode fn);

struct andordata
{
  label lab, slab, flab;
  gencode scode, fcode;
  void *sdata, *fdata;
  component arg2;
};

static void andorcode(void *_data, fncode fn)
{
  struct andordata *data = _data;

  set_label(data->lab, fn);
  generate_condition(data->arg2,
		     data->slab, data->scode, data->sdata,
		     data->flab, data->fcode, data->fdata,
		     fn);
}

void generate_condition(component condition,
			label slab, gencode scode, void *sdata,
			label flab, gencode fcode, void *fdata,
			fncode fn)
{
  struct andordata data;

  switch (condition->vclass)
    {
    case c_builtin:
      switch (condition->u.builtin.fn)
	{
	case b_sc_and: case b_sc_or:
	  {
	    component arg1 = condition->u.builtin.args->c;

	    data.arg2 = condition->u.builtin.args->next->c;
	    data.lab = new_label(fn);
	    data.slab = slab; data.scode = scode; data.sdata = sdata;
	    data.flab = flab; data.fcode = fcode; data.fdata = fdata;

	    if (condition->u.builtin.fn == b_sc_and)
	      generate_condition(arg1,
				 data.lab, andorcode, &data,
				 flab, NULL, NULL,
				 fn);
	    else
	      generate_condition(arg1,
				 slab, NULL, NULL,
				 data.lab, andorcode, &data,
				 fn);
	    return;
	  }
	case b_not:
	  /* Just swap conclusions */
	  generate_condition(condition->u.builtin.args->c,
			     flab, fcode, fdata,
			     slab, scode, sdata,
			     fn);
	  return;
	}
      /* Fall through */
    default:
      generate_component(condition, NULL, FALSE, fn);
      if (scode)
	{
	  branch(OPmbf3, flab, fn);
	  scode(sdata, fn);
	  if (fcode) fcode(fdata, fn);
	}
      else
	{
	  branch(OPmbt3, slab, fn);
	  if (fcode) fcode(fdata, fn);
	  else branch(OPmba3, flab, fn);
	}
      break;
    }
}

struct ifdata
{
  label slab, flab, endlab;
  component success, failure;
  bool discard;
};

static void ifs_code(void *_data, fncode fn)
{
  struct ifdata *data = _data;

  set_label(data->slab, fn);
  generate_component(data->success, NULL, data->discard, fn);
  branch(OPmba3, data->endlab, fn);
  if (!data->discard)
    adjust_depth(-1, fn);
}

static void iff_code(void *_data, fncode fn)
{
  struct ifdata *data = _data;

  set_label(data->flab, fn);
  generate_component(data->failure, NULL, data->discard, fn);
  branch(OPmba3, data->endlab, fn);
  if (!data->discard)
    adjust_depth(-1, fn);
}

void generate_if(component condition, component success, component failure,
		 bool discard, fncode fn)
{
  struct ifdata ifdata;

  ifdata.slab = new_label(fn);
  ifdata.flab = new_label(fn);
  ifdata.endlab = new_label(fn);
  ifdata.success = success;
  ifdata.failure = failure;
  ifdata.discard = discard;

  if (failure)
    generate_condition(condition, ifdata.slab, ifs_code, &ifdata,
		       ifdata.flab, iff_code, &ifdata, fn);
  else
    generate_condition(condition, ifdata.slab, ifs_code, &ifdata,
		       ifdata.endlab, NULL, NULL, fn);
  set_label(ifdata.endlab, fn);
  if (!discard)
    adjust_depth(1, fn);
}

struct whiledata {
  label looplab, mainlab, endlab;
  const char *continue_label;
  component code, next;
};

static void loop_body(struct whiledata *wdata, fncode fn)
{
  set_label(wdata->mainlab, fn);
  start_block(NULL, TRUE, TRUE, fn);
  if (wdata->continue_label)
    start_block(wdata->continue_label, TRUE, TRUE, fn);
  generate_component(wdata->code, NULL, TRUE, fn);
  if (wdata->continue_label)
    end_block(fn);
  end_block(fn);
  if (wdata->next)
    generate_component(wdata->next, NULL, TRUE, fn);
}

static void wmain_code(void *_data, fncode fn)
{
  struct whiledata *wdata = _data;

  loop_body(wdata, fn);
  branch(OPmba3, wdata->looplab, fn);
}

void generate_while(component condition, component iteration,
		    const char *continue_label, bool discard, fncode fn)
{
  struct whiledata wdata;

  start_block(NULL, FALSE, discard, fn);
  wdata.continue_label = continue_label;
  wdata.looplab = new_label(fn);
  wdata.mainlab = new_label(fn);
  wdata.endlab = new_label(fn);
  wdata.code = iteration;
  wdata.next = NULL;

  set_label(wdata.looplab, fn);
  generate_condition(condition, wdata.mainlab, wmain_code, &wdata,
		     wdata.endlab, NULL, NULL, fn);
  set_label(wdata.endlab, fn);
  if (!discard)
    generate_component(component_undefined, NULL, FALSE, fn);
  end_block(fn);
}

void generate_dowhile(component iteration, component condition,
		    const char *continue_label, bool discard, fncode fn)
{
  struct whiledata wdata;

  start_block(NULL, FALSE, discard, fn);
  wdata.continue_label = continue_label;
  wdata.looplab = new_label(fn);
  wdata.mainlab = new_label(fn);
  wdata.endlab = new_label(fn);
  wdata.code = iteration;
  wdata.next = NULL;

  loop_body(&wdata, fn);
  generate_condition(condition, wdata.mainlab, NULL, NULL,
		     wdata.endlab, NULL, NULL, fn);
  set_label(wdata.endlab, fn);
  if (!discard)
    generate_component(component_undefined, NULL, FALSE, fn);
  end_block(fn);
}

void generate_for(component init, component condition, component next,
		  component iteration, const char *continue_label,
		  bool discard, fncode fn)
{
  struct whiledata wdata;

  env_block_push(NULL); /* init may have local declarations */
  if (init)
    generate_component(init, NULL, TRUE, fn);

  start_block(NULL, FALSE, discard, fn);
  wdata.continue_label = continue_label;
  wdata.looplab = new_label(fn);
  wdata.mainlab = new_label(fn);
  wdata.endlab = new_label(fn);
  wdata.code = iteration;
  wdata.next = next;

  set_label(wdata.looplab, fn);
  if (condition)
    {
      generate_condition(condition, wdata.mainlab, wmain_code, &wdata,
			 wdata.endlab, NULL, NULL, fn);
      set_label(wdata.endlab, fn);
      if (!discard)
	generate_component(component_undefined, NULL, FALSE, fn);
    }
  else
    wmain_code(&wdata, fn);
  end_block(fn);
  env_block_pop();
}

void generate_args(clist args, fncode fn, u16 *_count)
{
  u16 count = 0;

  while (args)
    {
      count++;
      generate_component(args->c, NULL, FALSE, fn);
      args = args->next;
    }
  *_count = count;
}

static void generate_decls(vlist decls, fncode fn)
{
  /* Generate code for initialisers */
  for (; decls; decls = decls->next)
    if (decls->init)
      {
	u16 offset;
	mtype t;
	variable_class vclass = env_lookup(decls->l, decls->var, &offset, &t, FALSE);

	generate_component(decls->init, NULL, FALSE, fn);
	if (t != stype_any)
	  ins0(OPmscheck4 + t, fn);
	if (vclass == global_var)
	  massign(decls->l, offset, decls->var, fn);
	else
	  ins1(OPmwritel, offset, fn);
	ins0(OPmpop, fn);
      }

}

void generate_clist(clist cc, bool discard, fncode fn)
{
  /* Generate code for sequence */
  for (; cc; cc = cc->next)
    generate_component(cc->c, NULL, discard || cc->next, fn);
}

void generate_block(block b, bool discard, fncode fn)
{
  env_block_push(b->locals);
  generate_decls(b->locals, fn);
  generate_clist(b->sequence, discard, fn);
  env_block_pop();
}

void generate_execute(component acall, int count, fncode fn)
{
  if (count >= 16)
    log_error(acall->l, "no more than 15 arguments allowed");

  /* Optimise main case: calling a given global function. Also
     support implicit function declaration. */
  if (acall->vclass == c_recall)
    {
      u16 offset;
      mtype t;
      variable_class vclass = env_lookup(acall->l, acall->u.recall, &offset, &t, TRUE);

      if (vclass == global_var)
	{
	  mexecute(acall->l, offset, acall->u.recall, count, fn);
	  return;
	}
    }
  generate_component(acall, NULL, FALSE, fn);
  ins0(OPmexec4 + (count & 0xf), fn);
}

void generate_component(component comp, const char *mlabel, bool discard, fncode fn)
{
  clist args;

  switch (comp->vclass)
    {
    case c_assign:
      {
	u16 offset;
	mtype t;
	variable_class vclass = env_lookup(comp->l, comp->u.assign.symbol, &offset, &t, FALSE);
	component val = comp->u.assign.value;

	if (val->vclass == c_closure)
	  {
	    /* Defining a function, give it a name */
	    if (vclass == global_var)
	      val->u.closure->varname = comp->u.assign.symbol;
	    else
	      {
		char *varname = allocate(fnmemory(fn), strlen(comp->u.assign.symbol) + 7);

		sprintf(varname, "local-%s", comp->u.assign.symbol);
		val->u.closure->varname = varname;
	      }
	  }
	generate_component(comp->u.assign.value, NULL, FALSE, fn);
	if (t != stype_any)
	  ins0(OPmscheck4 + t, fn);
	if (vclass == global_var)
	  massign(comp->l, offset, comp->u.assign.symbol, fn);
	else if (vclass == closure_var)
	  ins1(OPmwritec, offset, fn);
	else
	  ins1(OPmwritel, offset, fn);
	/* Note: varname becomes a dangling pointer when fnmemory(fn) is
	   deallocated, but it is never used again so this does not cause
	   a problem. */
	break;
      }
    case c_recall:
      scompile_recall(comp->l, comp->u.recall, fn);
      break;
    case c_constant:
      ins_constant(make_constant(comp->u.cst, FALSE, fn), fn);
      break;
    case c_scheme:
      scheme_compile_mgc(comp->l, make_constant(comp->u.cst, TRUE, fn), discard, fn);
      discard = FALSE;
      break;
    case c_closure:
      generate_function(comp->u.closure, fn);
      break;
    case c_block:
      generate_block(comp->u.blk, discard, fn);
      discard = FALSE;
      break;
    case c_decl: 
      {
	vlist decl, next;

	/* declare variables one at a time (any x = y, y = 2; is an error) */
	for (decl = comp->u.decls; decl; decl = next)
	  {
	    next = decl->next;
	    decl->next = NULL;

	    env_declare(decl);
	    generate_decls(decl, fn);
	  }
	generate_component(component_undefined, NULL, FALSE, fn);
	break;
      }
    case c_labeled: {
      start_block(comp->u.labeled.name, FALSE, discard, fn);
      generate_component(comp->u.labeled.expression, comp->u.labeled.name, discard, fn);
      end_block(fn);
      discard = FALSE;
      break;
    }
    case c_exit:
      {
	bool discard_exit;
	label exitlab = exit_block(comp->u.labeled.name, FALSE, &discard_exit, fn);

	if (comp->u.labeled.expression != component_undefined && discard_exit)
	  warning(comp->l, "break result is ignored");
	generate_component(comp->u.labeled.expression, NULL, discard_exit, fn);
	if (exitlab)
	  branch(OPmba3, exitlab, fn);
	else 
	  {
	    if (!comp->u.labeled.name)
	      log_error(comp->l, "No loop to exit from");
	    else
	      log_error(comp->l, "No block labeled %s", comp->u.labeled.name);
	  }
	/* Callers expect generate_component to increase stack depth by 1  */
	if (discard_exit)
	  adjust_depth(1, fn);
	break;
      }
    case c_continue:
      {
	bool discard_exit; /* Meaningless for continue blocks */
	label exitlab = exit_block(comp->u.labeled.name, TRUE, &discard_exit, fn);

	if (exitlab)
	  branch(OPmba3, exitlab, fn);
	else 
	  {
	    if (comp->u.labeled.name[0] == '<')
	      log_error(comp->l, "No loop to continue");
	    else
	      log_error(comp->l, "No loop labeled %s", comp->u.labeled.name);
	  }
	/* Callers expect generate_component to increase stack depth by 1 (*/
	adjust_depth(1, fn);
	break;
      }
    case c_execute:
      {
	u16 count;

	generate_args(comp->u.execute->next, fn, &count);
	generate_execute(comp->u.execute->c, count, fn);
	break;
      }
    case c_builtin:
      args = comp->u.builtin.args;

      switch (comp->u.builtin.fn)
	{
	case b_if:
	  generate_if(args->c, args->next->c, NULL, TRUE, fn);
	  generate_component(component_undefined, NULL, FALSE, fn);
	  break;
	case b_ifelse:
	  generate_if(args->c, args->next->c, args->next->next->c, discard, fn);
	  discard = FALSE;
	  break;
	case b_sc_and: case b_sc_or:
	  generate_if(comp, component_true, component_false, discard, fn);
	  discard = FALSE;
	  break;

	case b_while:
	  enter_loop(fn);
	  generate_while(args->c, args->next->c, mlabel, discard, fn);
	  exit_loop(fn);
	  discard = FALSE;
	  break;

	case b_dowhile:
	  enter_loop(fn);
	  generate_dowhile(args->c, args->next->c, mlabel, discard, fn);
	  exit_loop(fn);
	  discard = FALSE;
	  break;

	case b_for:
	  enter_loop(fn);
	  generate_for(args->c, args->next->c, args->next->next->c,
		       args->next->next->next->c, mlabel, discard, fn);
	  exit_loop(fn);
	  discard = FALSE;
	  break;

	default:
	  {
	    u16 count;

	    assert(comp->u.builtin.fn < last_builtin);
	    generate_args(args, fn, &count);
	    ins0(builtin_ops[comp->u.builtin.fn], fn);
	    break;
	  }
	case b_cons:
	  {
	    u16 count;
	    u16 goffset;
	    mtype t;

	    assert(comp->u.builtin.fn < last_builtin);
	    generate_args(args, fn, &count);
	    goffset = global_lookup(fnglobals(fn),
				    builtin_functions[comp->u.builtin.fn], &t);
	    mexecute(comp->l, goffset, NULL, count, fn);
	    break;
	  }
	}
      break;
    default: assert(0);
    }
  if (discard)
    ins0(OPmpop, fn);
}

void generate_function(function f, fncode fn)
{
  struct code *c;
  struct string *help, *afilename, *varname;
  fncode newfn;
  vlist argument;
  u16 clen;
  i8 nargs;
  u8 nb_locals, *cvars;
  varlist closure, cvar;

  /* Code strings must be allocated before code (immutability restriction) */
  if (f->help)
    help = alloc_string(f->help);
  else
    help = NULL;
  GCPRO1(help);

  /* Make variable name (if present) */
  if (f->varname)
    varname = alloc_string(f->varname);
  else
    varname = NULL;
  GCPRO1(varname);

  /* Make filename string */
  afilename = make_filename(f->l.filename); 
  GCPRO1(afilename);

  if (f->varargs)
    /* varargs makes a vector from the first nargs entries of the stack and
       stores it in local value 0 */
    nargs = -1;
  else
    /* count the arguments */
    for (nargs = 0, argument = f->args; argument; argument = argument->next)
      nargs++;
  newfn = new_fncode(fnglobals(fn), f->l, FALSE, nargs);

  if (!f->varargs)
    {
      /* Generate code to check the argument types */
      for (nargs = 0, argument = f->args; argument; argument = argument->next) 
	{
	  if (argument->type != stype_any)
	    ins1(OPmvcheck4 + argument->type, nargs, newfn);

	  nargs++;
	}
    }

  /* Generate code of function */
  env_push(f->args, newfn);
  
  start_block("<return>", FALSE, FALSE, newfn);
  generate_component(f->value, NULL, FALSE, newfn);
  end_block(newfn);
  if (f->type != stype_any) ins0(OPmscheck4 + f->type, newfn);
  ins0(OPmreturn, newfn);
  closure = env_pop(&nb_locals);
  c = generate_fncode(newfn, nb_locals, help, varname, afilename, f->l.lineno);

  /* Generate code for creating closure */
  
  /* Count length of closure */
  clen = 0;
  for (cvar = closure; cvar; cvar = cvar->next) clen++;

  /* Generate closure */
  cvars = ins_closure(c, clen, fn);

  /* Add variables to it */
  for (cvar = closure; cvar; cvar = cvar->next)
    *cvars++ = (cvar->offset << 1) + cvar->vclass;

  delete_fncode(newfn);

  GCPOP(3);
}

static struct closure *compile_code(struct global_state *gstate, clist b)
{
  struct code *cc;
  u8 nb_locals;
  fncode top;
  location topl;
  struct string *afilename;

  /* Code strings must be allocated before code (immutability restriction) */
  afilename = make_filename(lexloc.filename);
  GCPRO1(afilename);

  erred = FALSE;
  env_reset();
  topl.filename = NULL;
  topl.lineno = 0;
  top = new_fncode(gstate, topl, TRUE, 0);
  env_push(NULL, top);		/* Environment must not be totally empty */
  generate_clist(b, FALSE, top);
  ins0(OPmreturn, top);
  env_pop(&nb_locals);
  cc = generate_fncode(top, nb_locals, NULL, NULL, afilename, 0);
  delete_fncode(top);

  GCPOP(1);

  if (erred) return NULL;
  else return alloc_closure0(cc);
}

struct compile_and_run_frame
{
  struct generic_frame g;
  enum { init, preparing, running } state;
  struct mprepare_state ps;
  block_t parser_block;
  mfile f;
  bool dontrun;
};

static void end_run(struct compile_and_run_frame *frame, int status)
{
  if (frame->f && frame->f->name)
    module_set(frame->ps.ccontext->gstate, frame->f->name, status);
  free_block(frame->parser_block);
}

static void continue_prepare(struct compile_and_run_frame *frame)
{
  value closure;
  struct global_state *gcopy;

  if (mprepare_load_next_start(&frame->ps))
    return;

  mprepare_vars(&frame->ps);

  gcopy = copy_global_state(frame->ps.ccontext->gstate);
  GCPRO1(gcopy);
  closure = compile_code(frame->ps.ccontext->gstate, frame->f->body);
  GCPOP(1);

  if (closure)
    {
      GCPRO1(closure);
      if (debug_lvl > 1)
	output_value(muderr, prt_examine, closure);
      frame->state = running;
      if (frame->dontrun)
	{
	  /* Just leave the closure itself as the result */
	  stack_reserve(sizeof(value));
	  stack_push(closure);
	}
      else
	push_closure(closure, 0);
      GCPOP(1);
      return;
    }
  global_set(frame->ps.ccontext->gstate, gcopy);
  runtime_error(error_compile_error);
}

static void compile_and_run_action(frameact action, u8 **ffp, u8 **fsp)
{
  struct compile_and_run_frame *frame = (struct compile_and_run_frame *)*ffp;

  switch (action)
    {
    case fa_execute:
      switch (frame->state)
	{
	case running: {
	  value result = stack_get(0);

	  end_run(frame, module_loaded);
	  /* Done. Pop frame */
	  FA_POP(&fp, &sp);

	  stack_push(result);
	  break;
	}
	case preparing:
	  mprepare_load_next_done(&frame->ps);
	  continue_prepare(frame);
	  break;
	default:
	  abort();
	}
      break;
    case fa_print:
      /* It's nicer without a message here */
      /*mputs("<compile>", muderr);*/
      break;
    case fa_unwind:
      if (frame->state != init)
	end_run(frame, module_error);
      goto pop;
    case fa_gcforward:
      forward((value *)&frame->ps.ccontext);
      /* fall through */
    case fa_pop:
    pop:
      pop_frame(ffp, fsp, sizeof(struct compile_and_run_frame));
      break;
    default: abort();
    }
}

CC compile_and_run(block_t region,
		   struct global_state *gstate,
		   const char *nicename, u8 *noreload,
		   bool dontrun)
{
  struct compile_and_run_frame *frame;
  struct compile_context *ccontext;

  GCPRO1(gstate);
  frame = push_frame(compile_and_run_action, sizeof(struct compile_and_run_frame));
  ccontext = (struct compile_context *)allocate_record(type_vector, 2);

  frame->dontrun = dontrun;
  frame->ps.ccontext = ccontext;
  ccontext->gstate = gstate;
  /* no evaluation_state yet */
  GCPOP(1);

  frame->state = init;
  if (!region)
    region = new_block();
  frame->parser_block = region;
  /* Set filename */
  lexloc.filename = bstrdup(region, nicename);

  normal_lexing();
  if ((frame->f = parse(frame->parser_block)))
    {
      if (noreload)
	{
	  if (frame->f->name &&
	      module_status(frame->ps.ccontext->gstate, frame->f->name) != module_unloaded)
	    {
	      free_block(frame->parser_block);
	      *noreload = TRUE;
	      FA_POP(&fp, &sp);
	      return;
	    }
	  *noreload = FALSE;
	}

      if (mprepare(&frame->ps, frame->parser_block, frame->f))
	{
	  frame->state = preparing;
	  continue_prepare(frame);
	  return;
	}
    }
  runtime_error(error_compile_error);
}

static block_t compile_block;

void compile_init(void)
{
  compile_block = new_block();

  /* Note: These definitions actually depend on those in types.h and runtime.c */
  component_undefined = new_component(compile_block, c_constant,
				      new_constant(compile_block, cst_int, 42));
  component_true = new_component(compile_block, c_constant,
				 new_constant(compile_block, cst_int, TRUE));
  component_false = new_component(compile_block, c_constant,
				  new_constant(compile_block, cst_int, FALSE));
  
  builtin_ops[b_eq] = OPmeq;
  builtin_ops[b_ne] = OPmne;
  builtin_ops[b_lt] = OPmlt;
  builtin_ops[b_le] = OPmle;
  builtin_ops[b_gt] = OPmgt;
  builtin_ops[b_ge] = OPmge;
  builtin_ops[b_bitor] = OPmbitor;
  builtin_ops[b_bitxor] = OPmbitxor;
  builtin_ops[b_bitand] = OPmbitand;
  builtin_ops[b_shift_left] = OPmshiftleft;
  builtin_ops[b_shift_right] = OPmshiftright;
  builtin_ops[b_add] = OPmadd;
  builtin_ops[b_subtract] = OPmsub;
  builtin_ops[b_multiply] = OPmmultiply;
  builtin_ops[b_divide] = OPmdivide;
  builtin_ops[b_remainder] = OPmremainder;
  builtin_ops[b_negate] = OPmnegate;
  builtin_ops[b_not] = OPmnot;
  builtin_ops[b_bitnot] = OPmbitnot;
  builtin_ops[b_ref] = OPmref;
  builtin_ops[b_set] = OPmset;
  builtin_functions[b_cons] = "cons";

  staticpro((value *)&last_filename);
  last_filename = alloc_string("");
  last_c_filename = xstrdup("");
}
