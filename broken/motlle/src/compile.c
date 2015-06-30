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
#include "mparser.h"
#include "call.h"
#include "table.h"
#include "interpret.h"
#include "lexer.h"

#include <string.h>
#include <stdlib.h>

static const char *builtin_functions[last_builtin];
static instruction builtin_ops[last_builtin];
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

void log_error(const char *msg, ...)
{
  va_list args;
  char err[4096];

  va_start(args, msg);
  vsprintf(err, msg, args);
  va_end(args);
  if (mudout) mflush(mudout);
  mprintf(muderr, "%s" EOL, err);
  if (muderr) mflush(muderr);
  erred = 1;
}

void warning(const char *msg, ...)
{
  va_list args;
  char err[4096];

  va_start(args, msg);
  vsprintf(err, msg, args);
  va_end(args);
  if (mudout) mflush(mudout);
  mprintf(muderr, "warning: %s" EOL, err);
  if (muderr) mflush(muderr);
}

value make_constant(constant c);

static value make_list(cstlist csts, int has_tail)
{
  struct list *l;

  if (has_tail && csts != NULL)
    {
      l = csts->cst ? make_constant(csts->cst) : NULL;
      csts = csts->next;
    }
  else
    l = NULL;

  GCPRO1(l);
  /* Remember that csts is in reverse order ... */
  while (csts)
    {
      value tmp = make_constant(csts->cst);

      l = alloc_list(tmp, l);
      SET_READONLY(l); SET_IMMUTABLE(l);
      csts = csts->next;
    }
  GCPOP(1);

  return l;
}

static value make_array(cstlist csts)
{
  struct list *l;
  struct vector *v;
  uvalue size = 0, i;
  cstlist scan;
  
  for (scan = csts; scan; scan = scan->next) size++;

  /* This intermediate step is necessary as v is IMMUTABLE
     (so must be allocated after its contents) */
  l = make_list(csts, 0);
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

static value make_table(cstlist csts)
{
  struct table *t = alloc_table(DEF_TABLE_SIZE);
  
  GCPRO1(t);
  for (; csts; csts = csts->next)
    table_set(t, csts->cst->u.constpair->cst1->u.string,
	      make_constant(csts->cst->u.constpair->cst2));
  table_foreach(t, protect_symbol);
  SET_READONLY(t);
  GCPOP(1);

  return t;
}

static value make_symbol(cstpair p)
{
  struct symbol *sym;
  struct string *s = alloc_string(p->cst1->u.string);
 
  GCPRO1(s);
  SET_IMMUTABLE(s); SET_READONLY(s);
  sym = alloc_symbol(s, make_constant(p->cst2));
  SET_IMMUTABLE(sym); SET_READONLY(sym);
  GCPOP(1);
  return sym;
}

value make_constant(constant c)
{
  struct obj *cst;

  switch (c->vclass)
    {
    case cst_string:
      cst = (value)alloc_string(c->u.string);
      SET_READONLY(cst); SET_IMMUTABLE(cst);
      return cst;
    case cst_list: return make_list(c->u.constants, 1);
    case cst_array: return make_array(c->u.constants);
    case cst_int: return makeint(c->u.integer);
    case cst_table: return make_table(c->u.constants);
    case cst_symbol: return make_symbol(c->u.constpair);
    default:
      abort();
    }
}

typedef void (*gencode)(void *data, fncode fn);

struct code *generate_function(function f, int toplevel, fncode fn);
void generate_component(component comp, fncode fn);
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
      generate_component(condition, fn);
      if (scode)
	{
	  branch(op_branch_z1, flab, fn);
	  scode(sdata, fn);
	  if (fcode) fcode(fdata, fn);
	}
      else
	{
	  branch(op_branch_nz1, slab, fn);
	  if (fcode) fcode(fdata, fn);
	  else branch(op_branch1, flab, fn);
	}
      break;
    }
}

struct ifdata
{
  label slab, flab, endlab;
  component success, failure;
};

static void ifs_code(void *_data, fncode fn)
{
  struct ifdata *data = _data;

  set_label(data->slab, fn);
  generate_component(data->success, fn);
  branch(op_branch1, data->endlab, fn);
  adjust_depth(-1, fn);
}

static void iff_code(void *_data, fncode fn)
{
  struct ifdata *data = _data;

  set_label(data->flab, fn);
  generate_component(data->failure, fn);
  branch(op_branch1, data->endlab, fn);
  adjust_depth(-1, fn);
}

void generate_if(component condition, component success, component failure,
		 fncode fn)
{
  struct ifdata ifdata;

  ifdata.slab = new_label(fn);
  ifdata.flab = new_label(fn);
  ifdata.endlab = new_label(fn);
  ifdata.success = success;
  ifdata.failure = failure;

  generate_condition(condition, ifdata.slab, ifs_code, &ifdata,
		     ifdata.flab, iff_code, &ifdata, fn);
  set_label(ifdata.endlab, fn);
  adjust_depth(1, fn);
}

struct whiledata {
  label looplab, mainlab, exitlab, endlab;
  component code;
};

static void wmain_code(void *_data, fncode fn)
{
  struct whiledata *wdata = _data;

  set_label(wdata->mainlab, fn);
  generate_component(wdata->code, fn);
  branch(op_loop1, wdata->looplab, fn);
}

static void wexit_code(void *_data, fncode fn)
{
  struct whiledata *wdata = _data;

  set_label(wdata->exitlab, fn);
  generate_component(component_undefined, fn);
  branch(op_branch1, wdata->endlab, fn);
}

void generate_while(component condition, component iteration, fncode fn)
{
  struct whiledata wdata;

  wdata.looplab = new_label(fn);
  wdata.mainlab = new_label(fn);
  wdata.exitlab = new_label(fn);
  wdata.endlab = new_label(fn);
  wdata.code = iteration;

  set_label(wdata.looplab, fn);
  generate_condition(condition, wdata.mainlab, wmain_code, &wdata,
		     wdata.exitlab, wexit_code, &wdata, fn);
  set_label(wdata.endlab, fn);
}

void generate_args(clist args, fncode fn, u16 *_count)
{
  u16 count = 0;

  while (args)
    {
      count++;
      generate_component(args->c, fn);
      args = args->next;
    }
  *_count = count;
}

void generate_block(block b, fncode fn)
{
  clist cc = b->sequence;

  env_block_push(b->locals);

  /* Generate code for sequence */
  for (; cc; cc = cc->next)
    {
      generate_component(cc->c, fn);
      if (cc->next) ins0(op_discard, fn);
    }
  env_block_pop();
}

void generate_execute(component acall, int count, fncode fn)
{
  /* Optimise main case: calling a given global function */
  if (acall->vclass == c_recall)
    {
      u16 offset;
      variable_class vclass = env_lookup(acall->u.recall, &offset);

      if (vclass == global_var)
	{
	  mexecute(offset, acall->u.recall, count, fn);
	  return;
	}
    }
  generate_component(acall, fn);
  ins1(op_execute, count, fn);
}

void generate_component(component comp, fncode fn)
{
  clist args;

  switch (comp->vclass)
    {
    case c_assign:
      {
	u16 offset;
	variable_class vclass = env_lookup(comp->u.assign.symbol, &offset);
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
	generate_component(comp->u.assign.value, fn);
	if (vclass == global_var)
	  massign(offset, comp->u.assign.symbol, fn);
	else
	  ins1(op_assign + vclass, offset, fn);
	/* Note: varname becomes a dangling pointer when fnmemory(fn) is
	   deallocated, but it is never used again so this does not cause
	   a problem. */
	break;
      }
    case c_recall:
      {
	u16 offset;
	variable_class vclass = env_lookup(comp->u.recall, &offset);

	if (vclass == global_var) mrecall(offset, comp->u.recall, fn);
	else ins1(op_recall + vclass, offset, fn);
	break;
      }
    case c_constant:
      ins_constant(make_constant(comp->u.cst), fn);
      break;
    case c_closure:
      {
	value newfn = generate_function(comp->u.closure, FALSE, fn);

	add_constant(newfn, fn);
	break;
      }
    case c_block:
      generate_block(comp->u.blk, fn);
      break;
    case c_labeled:
      start_block(comp->u.labeled.name, fn);
      generate_component(comp->u.labeled.expression, fn);
      end_block(fn);
      break;
    case c_exit:
      generate_component(comp->u.labeled.expression, fn);
      if (!exit_block(comp->u.labeled.name, fn)) {
	if (!comp->u.labeled.name)
	  log_error("No loop to exit from");
	else
	  log_error("No block labeled %s", comp->u.labeled.name);
      }
      break;
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
	  generate_if(args->c,
		      new_component(fnmemory(fn), c_block,
				    new_codeblock(fnmemory(fn), NULL,
				    new_clist(fnmemory(fn), args->next->c,
				    new_clist(fnmemory(fn), component_undefined, NULL)))),
		      component_undefined,
		      fn);
	  break;
	case b_ifelse:
	  generate_if(args->c, args->next->c, args->next->next->c, fn);
	  break;
	case b_sc_and: case b_sc_or:
	  generate_if(comp, component_true, component_false, fn);
	  break;

	case b_while:
	  generate_while(args->c, args->next->c, fn);
	  break;

	case b_loop:
	  {
	    label loop = new_label(fn);

	    set_label(loop, fn);
	    start_block(NULL, fn);
	    generate_component(args->c, fn);
	    branch(op_loop1, loop, fn);
	    end_block(fn);
	    adjust_depth(1, fn);
	    break;
	  }

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

	    assert(comp->u.builtin.fn < last_builtin);
	    generate_args(args, fn, &count);
	    goffset = global_lookup(fnglobals(fn),
				    builtin_functions[comp->u.builtin.fn]);
	    mexecute(goffset, NULL, count, fn);
	    break;
	  }
	}
      break;
    default: assert(0);
    }
}

struct code *generate_function(function f, int toplevel, fncode fn)
{
  struct code *c;
  struct string *help, *afilename, *varname;
  fncode newfn;
  vlist argument;
  u16 clen;
  i8 nargs;
  varlist closure, cvar;

  /* Make help string (must be allocated before code (immutability restriction)) */
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
  afilename = make_filename(f->filename);
  GCPRO1(afilename);

  if (f->varargs)
    /* varargs makes a vector from the first nargs entries of the stack and
       stores it in local value 0 */
    nargs = -1;
  else
    /* count the arguments */
    for (nargs = 0, argument = f->args; argument; argument = argument->next)
      nargs++;
  newfn = new_fncode(fnglobals(fn), toplevel, nargs);

  if (!f->varargs)
    {
      /* Generate code to check the argument types */
      for (nargs = 0, argument = f->args; argument; argument = argument->next) 
	{
	  if (argument->type != stype_any)
	    ins1(op_typecheck + argument->type, nargs, newfn);

	  nargs++;
	}
    }

  /* Generate code of function */
  env_push(f->args, newfn);
  
  start_block("function", newfn);
  generate_component(f->value, newfn);
  end_block(newfn);
  /*if (f->type != stype_any) ins1(op_typecheck + f->type, 0, newfn);*/
  ins0(op_return, newfn);
  peephole(newfn);
  c = generate_fncode(newfn, help, varname, afilename, f->lineno);
  closure = env_pop(&c->nb_locals);

  /* Generate code for creating closure */
  
  /* Count length of closure */
  clen = 0;
  for (cvar = closure; cvar; cvar = cvar->next) clen++;

  /* Generate closure */
  ins1(op_closure, clen, fn);

  /* Add variables to it */
  for (cvar = closure; cvar; cvar = cvar->next)
    add_ins((cvar->offset << 1) + cvar->vclass, fn);

  delete_fncode(newfn);

  GCPOP(3);

  return c;
}

static struct closure *compile_code(struct global_state *gstate, block b)
{
  struct code *cc;
  u8 dummy;
  fncode top;

  erred = FALSE;
  env_reset();
  top = new_fncode(gstate, TRUE, 0);
  env_push(NULL, top);		/* Environment must not be totally empty */
  cc = generate_function(new_function(fnmemory(top), stype_any, NULL, NULL,
				      new_component(fnmemory(top), c_block, b),
				      0, ""), TRUE, top);
  add_constant(NULL, top);
  GCPRO1(cc);
  generate_fncode(top, NULL, NULL, NULL, 0);
  env_pop(&dummy);
  GCPOP(1);
  delete_fncode(top);

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

  if (mprepare_load_next_start(&frame->ps))
    return;

  mprepare_vars(&frame->ps);

  closure = compile_code(frame->ps.ccontext->gstate, frame->f->body);

  if (closure)
    {
#if 0
      output_value(muderr, prt_examine, closure);
#endif
      frame->state = running;
      if (frame->dontrun)
	{
	  /* Just leave the closure itself as the result */
	  GCPRO1(closure);
	  stack_reserve(sizeof(value));
	  GCPOP(1);
	  stack_push(closure);
	}
      else
	push_closure(closure, 0);
      return;
    }
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
  struct compile_and_run_frame *frame =
    push_frame(compile_and_run_action, sizeof(struct compile_and_run_frame));
  struct compile_context *ccontext =
    (struct compile_context *)allocate_record(type_vector, 2);

  frame->dontrun = dontrun;
  frame->ps.ccontext = ccontext;
  ccontext->gstate = gstate;
  /* no evaluation_state yet */

  frame->state = init;
  if (!region)
    region = new_block();
  frame->parser_block = region;
  /* Set filename */
  filename = bstrdup(region, nicename);

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
  
  builtin_ops[b_or] = op_builtin_or;
  builtin_ops[b_and] = op_builtin_and;
  builtin_ops[b_eq] = op_builtin_eq;
  builtin_ops[b_ne] = op_builtin_neq;
  builtin_ops[b_lt] = op_builtin_lt;
  builtin_ops[b_le] = op_builtin_le;
  builtin_ops[b_gt] = op_builtin_gt;
  builtin_ops[b_ge] = op_builtin_ge;
  builtin_ops[b_bitor] = op_builtin_bitor;
  builtin_ops[b_bitxor] = op_builtin_bitxor;
  builtin_ops[b_bitand] = op_builtin_bitand;
  builtin_ops[b_shift_left] = op_builtin_shift_left;
  builtin_ops[b_shift_right] = op_builtin_shift_right;
  builtin_ops[b_add] = op_builtin_add;
  builtin_ops[b_subtract] = op_builtin_sub;
  builtin_ops[b_multiply] = op_builtin_multiply;
  builtin_ops[b_divide] = op_builtin_divide;
  builtin_ops[b_remainder] = op_builtin_remainder;
  builtin_ops[b_negate] = op_builtin_negate;
  builtin_ops[b_not] = op_builtin_not;
  builtin_ops[b_bitnot] = op_builtin_bitnot;
  builtin_ops[b_ref] = op_builtin_ref;
  builtin_ops[b_set] = op_builtin_set;
  builtin_functions[b_cons] = "cons";

  staticpro((value *)&last_filename);
  last_filename = alloc_string("");
  last_c_filename = xstrdup("");
}
