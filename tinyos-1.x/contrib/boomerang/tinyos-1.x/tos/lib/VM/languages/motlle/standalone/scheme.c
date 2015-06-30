#include "mudlle.h"
#include "ins.h"
#include "code.h"
#include "scompile.h"
#include "compile.h"
#include "lexer.h"
#include "env.h"
#include "mcompile.h"
#include "scheme.h"

/* mgc stands for may cause garbage collection (=> must protect gcable
   variables)
*/

#include <string.h>

static void ins_undefined(bool discard, fncode fn)
{
  if (!discard)
    ins_constant(undefined_value, fn);
}

static void terminate(label lab, bool discard, fncode fn)
{
  branch(OPmba3, lab, fn);
  if (!discard)
    adjust_depth(-1, fn);
}

static void entry_with_data(label lab, bool discard, fncode fn)
{
  set_label(lab, fn);
  if (!discard)
    adjust_depth(1, fn);
}

static value extract_location(value v, location *loc)
{
  if (TYPE(v, type_pair))
    {
      struct list *l = v;
      struct extptr *locptr = l->car;
      *loc = *(location *)locptr->external;
      return l->cdr;
    }
  else
    return v;
}

static value skip_location(value v)
{
  if (TYPE(v, type_pair))
    return ((struct list *)v)->cdr;
  else
    return v;
}

static value filter_locations_mgc(value v)
{
  struct list *newv = NULL, *end = NULL;

  if (!TYPE(v, type_pair))
    return v;

  GCPRO2(newv, end);
  GCPRO1(v);
  while (TYPE(v, type_pair))
    {
      struct list *newend = alloc_list(filter_locations_mgc(((struct list *)v)->car), NULL);

      if (!newv)
	newv = end = newend;
      else
	{
	  end->cdr = newend;
	  end = newend;
	}
    }
  end->cdr = v;
  GCPOP(3);
  return newv;
}

static int list_length(value v)
{
  int len = 0;

  for (; TYPE(v, type_pair); v = ((struct list *)v)->cdr)
    len++;

  if (v)
    return -len - 1;
  else
    return len;
}

static value nthtail(struct list *l, int n)
{
  while (--n)
    l = l->cdr;

  return l;
}

static value nth(struct list *l, int n)
{
  while (--n)
    l = l->cdr;

  return l->car;
}

static const char *symname(value sym)
{
  struct symbol *s = sym;

  return s->name->str;
}

static const char *sym2str(block_t region, value sym)
{
  return bstrdup(region, symname(sym));
}

static vlist str2vlist(block_t region, location l, const char *str)
{
  vlist v = new_vlist(region, str, stype_any, NULL, NULL);
  v->l = l;
  return v;
}

static vlist sym2vlist(block_t region, location l, value sym)
{
  return str2vlist(region, l, sym2str(region, sym));
}

static bool is_keyword(value x, const char *keyword)
{
  return TYPE(x, type_symbol) && !strcmp(keyword, symname(x));
}

static struct {
  const char *name;
  int nargs;
  int builtin;
} builtins[] = {
  { NULL, 0, last_builtin },
  { "eq?", 2, b_eq },
  { "eqv?", 2, b_eq },
  { "=", 2, b_eq },
  { "<", 2, b_lt },
  { "<=", 2, b_le },
  { ">", 2, b_gt },
  { ">=", 2, b_ge },
  { "|", -1, b_bitor },
  { "^", -1, b_bitxor },
  { "&", -1, b_bitand },
  { "<<", 2, b_shift_left },
  { ">>", 2, b_shift_right },
  { "~", 1, b_bitnot },
  { "+", -1, b_add },
  { "-", 2, b_subtract },
  { "-", 1, b_negate },
  { "*", -1, b_multiply },
  { "remainder", 2, b_remainder },
  { "not", 1, b_not },
  { "any-ref", 2, b_ref },
  { "vector-ref", 2, b_ref },
  { "string-ref", 2, b_ref },
  { "any-set!", 3, b_set },
  { "vector-set!", 3, b_set },
  { "string-set!", 3, b_set },
};

static int lookup_builtin(const char *name, int nargs)
{
  int i;

  for (i = 1; i < sizeof builtins / sizeof *builtins; i++)
    if ((nargs == builtins[i].nargs || builtins[i].nargs == -1) &&
	!strcmp(name, builtins[i].name))
      return i;

  return -1;
}

static int is_builtin_call(value v, fncode fn)
{
  if (TYPE(v, type_pair))
    {
      struct list *call = skip_location(v);

      if (TYPE(call->car, type_symbol))
	{
	  struct symbol *called = call->car;

	  return lookup_builtin(symname(called), list_length(call->cdr));
	}
    }
  return -1;
}

static void compile_args_mgc(location l, struct list *args, fncode fn)
{
  GCPRO1(args);
  while (args)
    {
      scheme_compile_mgc(l, args->car, FALSE, fn);
      args = args->cdr;
    }
  GCPOP(1);
}

static void compile_call_mgc(location l, value tocall, int nargs, bool discard,
			     fncode fn) 
{
  /* Optimise main case: calling a given global function. Also
     support implicit function declaration. */
  if (TYPE(tocall, type_symbol))
    {
      const char *name = sym2str(fnmemory(fn), tocall);
      u16 offset;
      mtype t;
      variable_class vclass = env_lookup(l, name, &offset, &t, TRUE);

      if (vclass == global_var)
	{
	  int builtin = lookup_builtin(name, nargs);

	  if (builtin != -1)
	    {
	      int i, count;

	      if (builtins[builtin].nargs == -1)
		count = nargs - 1;
	      else
		count = 1;

	      for (i = 0; i < count; i++)
		ins0(builtin_ops[builtins[builtin].builtin], fn);
	    }
	  else
	    mexecute(l, offset, name, nargs, fn);

	  if (discard)
	    ins0(OPmpop, fn);
	  return;
	}
    }
  scheme_compile_mgc(l, tocall, FALSE, fn);
  ins0(OPmexec4 + (nargs & 0xf), fn);

  if (discard)
    ins0(OPmpop, fn);
}

typedef void (*gencode)(location l, void *data, fncode fn);

void sgen_condition_mgc(location l, value condition, bool preservetrue,
			label slab, gencode scode, void *sdata,
			label flab, gencode fcode, void *fdata,
			fncode fn);

struct andordata
{
  label lab, slab, flab;
  struct list *args;
  bool and;
  bool preservetrue;
};

static void sgen_condition_andor_mgc(location l, void *_data, fncode fn) 
{
  struct andordata *data = _data;

  if (data->args->cdr) /* not last clause */
    {
      struct list *clause = data->args->car;

      data->args = data->args->cdr;

      if (data->lab)
	set_label(data->lab, fn);
      data->lab = new_label(fn);
      if (data->and)
	sgen_condition_mgc(l, clause, FALSE,
			   data->lab, sgen_condition_andor_mgc, data,
			   data->flab, NULL, NULL, fn);
      else /* or */
	sgen_condition_mgc(l, clause, data->preservetrue,
			   data->slab, NULL, NULL, 
			   data->lab, sgen_condition_andor_mgc, data, fn);
    }
}

void sgen_condition_mgc(location l, value condition, bool preservetrue,
			label slab, gencode scode, void *sdata,
			label flab, gencode fcode, void *fdata,
			fncode fn)
{
 repeat:
  if (builtins[is_builtin_call(condition, fn)].builtin == b_not &&
      !preservetrue)
    {
      /* Just swap conclusions */
      sgen_condition_mgc(l, nth(skip_location(condition), 2), FALSE,
			 flab, fcode, fdata, slab, scode, sdata, fn);
      return;
    }

  /* check for non-degenerate and, or */
  if (list_length(skip_location(condition)) >= 2)
    {
      struct list *condlist = extract_location(condition, &l);
      bool is_or = is_keyword(condlist->car, "or");
      bool is_and = is_keyword(condlist->car, "and");

      if (is_or || is_and)
	{
	  struct andordata data;

	  data.lab = NULL;
	  data.slab = slab;
	  data.flab = flab;
	  data.args = condlist->cdr;
	  data.and = is_and;
	  data.preservetrue = preservetrue;
	  GCPRO1(data.args);
	  sgen_condition_andor_mgc(l, &data, fn);
	  GCPOP(1);
	  condition = data.args->car;
	  goto repeat;
	}
    }

  /* Default behaviour */
  scheme_compile_mgc(l, condition, FALSE, fn);
  if (scode)
    {
      branch(preservetrue ? OPmbfp3 : OPmbf3, flab, fn);
      scode(l, sdata, fn);
      if (fcode)
	fcode(l, fdata, fn);
    }
  else
    {
      branch(preservetrue ? OPmbtp3 : OPmbt3, slab, fn);
      if (fcode)
	fcode(l, fdata, fn);
      else
	branch(OPmba3, flab, fn);
    }
}

struct ifdata
{
  label slab, flab, endlab;
  value success, failure;
  bool discard;
};

static void ifs_code_mgc(location l, void *_data, fncode fn)
{
  struct ifdata *data = _data;

  set_label(data->slab, fn);
  scheme_compile_mgc(l, data->success, data->discard, fn);
  terminate(data->endlab, data->discard, fn);
}

static void iff_code_mgc(location l, void *_data, fncode fn)
{
  struct ifdata *data = _data;

  set_label(data->flab, fn);
  scheme_compile_mgc(l, data->failure, data->discard, fn);
  terminate(data->endlab, data->discard, fn);
}

void sgen_if_mgc(location l, value condition, value success, value failure,
		 bool discard, fncode fn) 
{
  struct ifdata ifdata;

  ifdata.slab = new_label(fn);
  ifdata.flab = new_label(fn);
  ifdata.endlab = new_label(fn);
  ifdata.success = success;
  ifdata.failure = failure;
  ifdata.discard = discard;
  GCPRO2(ifdata.success, ifdata.failure);
  sgen_condition_mgc(l, condition, FALSE,
		     ifdata.slab, ifs_code_mgc, &ifdata,
		     ifdata.flab, iff_code_mgc, &ifdata, fn);
  GCPOP(2);
  entry_with_data(ifdata.endlab, discard, fn);
}

static void compile_quote(location l, struct list *args, bool discard, fncode fn)
{
  if (!discard)
    ins_constant(skip_location(args->car), fn);
}

void compile_begin_mgc(location l, struct list *blk, bool discard, fncode fn) 
{
  GCPRO1(blk);
  for (; blk; blk = blk->cdr)
    scheme_compile_mgc(l, blk->car, blk->cdr || discard, fn);
  GCPOP(1);
}

static bool bind_define(location l, value v, fncode fn)
{
  if (TYPE(v, type_pair))
    {
      struct list *expr = extract_location(v, &l);

      if (is_keyword(expr->car, "define"))
	{
	  if (list_length(expr->cdr) >= 2)
	    {
	      expr = expr->cdr;
	  
	      if (TYPE(expr->car, type_pair))
		expr = skip_location(expr->car);
	      if (TYPE(expr->car, type_symbol))
		env_declare(sym2vlist(fnmemory(fn), l, expr->car));

	    }
	  return TRUE;
	}
      if (is_keyword(expr->car, "begin"))
	{
	  /* the definitions at the start of an embedded begin block
	     should also be declared - this is not quite what the spec
	     says as we allow random non-define stuff after some initial
	     defines */
	  struct list *defines;

	  for (defines = expr->cdr;
	       TYPE(defines, type_pair) && bind_define(l, defines->car, fn); 
	       defines = defines->cdr)
	    ;
	  if (defines != expr->cdr)
	    return TRUE;
	}
    }
  return FALSE;
}

void compile_block_mgc(location l, struct list *blk, bool discard, fncode fn)
{
  struct list *defines;

  for (defines = blk; defines && bind_define(l, defines->car, fn); )
    defines = defines->cdr;

  GCPRO1(blk);
  for (; blk; blk = blk->cdr)
    scheme_compile_mgc(l, blk->car, blk->cdr || discard, fn);
  GCPOP(1);
}

static void sgen_function_mgc(location l, struct string *varname, value formals,
			      value body, bool discard, fncode fn)
{
  struct code *c;
  struct string *help, *afilename;
  fncode newfn;
  vlist fnargs = NULL;
  u16 clen;
  i8 nargs;
  u8 nb_locals, *cvars;
  varlist closure, cvar;
  block_t region = fnmemory(fn);

  if (discard)
    return;

  GCPRO2(varname, formals);
  GCPRO1(body);
  help = NULL;
  GCPRO1(help);

  /* Make filename string */
  afilename = make_filename(l.filename); 
  GCPRO1(afilename);

  nargs = list_length(formals);
  if (nargs >= 16)
    log_error(l, "no more than 15 parameters allowed");
  if (nargs < -1) /* we don't support (arg1 ... argn . argrest) */
    {
      log_error(l, "(x1 ... xn . rest) parameter syntax not supported");
      nargs = 0;
    }
  else if (nargs == -1)
    {
      if (!TYPE(formals, type_symbol))
	log_error(l, "symbol expected");
      else
	fnargs = sym2vlist(region, l, formals);
    }
  else
    {
      struct list *actual_args;
      vlist *nextarg = &fnargs;

      for (actual_args = formals; actual_args; actual_args = actual_args->cdr)
	if (!TYPE(actual_args->car, type_symbol))
	  log_error(l, "function parameters must be symbols");
	else
	  {
	    *nextarg = sym2vlist(region, l, actual_args->car);
	    nextarg = &(*nextarg)->next;
	  }
    }
  newfn = new_fncode(fnglobals(fn), l, FALSE, nargs);

  /* Generate code of function */
  env_push(fnargs, newfn);
  
  start_block("<return>", FALSE, FALSE, newfn);
  compile_block_mgc(l, body, FALSE, newfn);
  end_block(newfn);
  ins0(OPmreturn, newfn);
  closure = env_pop(&nb_locals);
  c = generate_fncode(newfn, nb_locals, help, varname, afilename, l.lineno);

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

  GCPOP(5);
}

static void compile_lambda_mgc(location l, struct list *lambda_args, bool discard, fncode fn)
{
  sgen_function_mgc(l, NULL, skip_location(lambda_args->car), lambda_args->cdr, discard, fn);
}

static void compile_if_mgc(location l, struct list *args, bool discard, fncode fn)
{
  value cond, true;

  cond = args->car;
  args = args->cdr;
  true = args->car;
  args = args->cdr;
  if (args)
    sgen_if_mgc(l, cond, true, args->car, discard, fn);
  else
    sgen_if_mgc(l, cond, true, undefined_value, discard, fn);
}

static void sgen_assign_mgc(location l, const char *name, bool discard, fncode fn)
{
  u16 offset;
  mtype t;
  variable_class vclass = env_lookup(l, name, &offset, &t, FALSE);

  if (vclass == global_var)
    massign(l, offset, name, fn);
  else if (vclass == closure_var)
    ins1(OPmwritec, offset, fn);
  else
    ins1(OPmwritel, offset, fn);

  if (discard)
    ins0(OPmpop, fn);
}

static void compile_setb_mgc(location l, struct list *args, bool discard, fncode fn)
{
  GCPRO1(args);
  scheme_compile_mgc(l, nth(args, 2), FALSE, fn);
  GCPOP(1);

  if (!TYPE(args->car, type_symbol))
    {
      log_error(l, "must assign a symbol");
      return;
    }

  sgen_assign_mgc(l, sym2str(fnmemory(fn), args->car), discard, fn);
}

static void define_of_mgc(location l, vlist var, fncode fn)
{
  /* in-block declarations are handled by compile_block */
  if (fntoplevel(fn))
    env_declare(var);
}

static void compile_define_mgc(location l, struct list *args, bool discard, fncode fn)
{
  vlist vfn = NULL;
  int toplevel = fntoplevel(fn);

  GCPRO1(args);
  if (TYPE(args->car, type_symbol) && list_length(args) == 2)
    {
      vfn = sym2vlist(fnmemory(fn), l, args->car);
      define_of_mgc(l, vfn, fn);
      scheme_compile_mgc(l, nth(args, 2), FALSE, fn);
    }
  else if (TYPE(args->car, type_pair))
    {
      struct list *fndecl = extract_location(args->car, &l);

      if (TYPE(fndecl->car, type_symbol))
	{
	  struct symbol *name = fndecl->car;

	  vfn = sym2vlist(fnmemory(fn), l, name);
	  GCPRO2(fndecl, name);
	  define_of_mgc(l, vfn, fn);
	  GCPOP(2);
	  sgen_function_mgc(l, name->name, fndecl->cdr, args->cdr, FALSE, fn);
	}
    }
  if (!vfn)
    log_error(l, "invalid define syntax");
  else
    sgen_assign_mgc(l, vfn->var, discard, fn);
  GCPOP(1);
}

static struct symbol *check_binding(location l, value binding, int extra)
{
  value sym;

  if (list_length(binding) != 2 + extra)
    {
      log_error(l, "invalid variable binding");
      return NULL;
    }

  sym = ((struct list *)binding)->car;
  if (TYPE(sym, type_symbol))
    return sym;

  log_error(l, "first element of binding list must be a symbol");
  return NULL;
}

static void sgen_binding_init_mgc(location l, struct list *binding, fncode fn)
{
  scheme_compile_mgc(l, nth(binding, 2), FALSE, fn);
}

static void sgen_binding_decl(location l, struct list *binding, fncode fn)
{
  env_declare(sym2vlist(fnmemory(fn), l, binding->car));
}

static void sgen_binding_assign_mgc(location l, struct list *binding, fncode fn)
{
  sgen_assign_mgc(l, symname(binding->car), TRUE, fn);
}

static void let_body_mgc(location l, struct list *body, bool discard, fncode fn)
{
  compile_block_mgc(l, body, discard, fn);
  env_block_pop();
}

static bool let_bindings_mgc(location l, struct list *bindings, int extra, fncode fn)
{
  if (TYPE(bindings, type_pair))
    {
      value binding;
      int ok;

      binding = extract_location(bindings->car, &l);
      ok = check_binding(l, binding, extra) != NULL;

      GCPRO2(binding, bindings);
      if (ok)
	sgen_binding_init_mgc(l, binding, fn);

      ok = let_bindings_mgc(l, bindings->cdr, extra, fn) && ok;

      if (ok)
	{
	  sgen_binding_decl(l, binding, fn);
	  sgen_binding_assign_mgc(l, binding, fn);
	}
      GCPOP(2);

      return ok;
    }
  else if (bindings)
    {
      log_error(l, "invalid bindings");
      return FALSE;
    }
  else
    return TRUE;
}

static void compile_named_let_mgc(location l, struct list *args, bool discard, fncode fn)
{
  struct symbol *name, *parm;
  struct list *bindings, *parameters = NULL, *last_parameter = NULL;
  const char *cname;
  int nargs = 0;

  if (list_length(args) < 3)
    {
      log_error(l, "no body in named let");
      return;
    }

  env_block_push(NULL);
  cname = sym2str(fnmemory(fn), args->car);
  env_declare(str2vlist(fnmemory(fn), l, cname));

  bindings = extract_location(nth(args, 2), &l);
  GCPRO2(bindings, args);
  GCPRO2(parameters, last_parameter);
  for (; TYPE(bindings, type_pair); bindings = bindings->cdr)
    {
      value binding;

      binding = extract_location(bindings->car, &l);

      GCPRO1(binding);
      if ((parm = check_binding(l, binding, 0)))
	{
	  struct list *parmtail = alloc_list(parm, NULL);

	  if (!parameters)
	    parameters = last_parameter = parmtail;
	  else
	    {
	      last_parameter->cdr = parmtail;
	      last_parameter = parmtail;
	    }

	  sgen_binding_init_mgc(l, binding, fn);
	  nargs++;
	}
      GCPOP(1);
    }
  if (bindings)
    log_error(l, "invalid bindings");
  name = args->car;
  sgen_function_mgc(l, name->name, parameters, nthtail(args, 3), FALSE, fn);
  sgen_assign_mgc(l, cname, FALSE, fn);
  ins0(OPmexec4 + (nargs & 0xf), fn);
  if (discard)
    ins0(OPmpop, fn);
  env_block_pop();
  GCPOP(4);
}

static void compile_let_mgc(location l, struct list *args, bool discard, fncode fn)
{
  value bindings;

  if (TYPE(args->car, type_symbol))
    {
      compile_named_let_mgc(l, args, discard, fn);
      return;
    }
  env_block_push(NULL);
  GCPRO1(args);
  bindings = extract_location(args->car, &l);
  let_bindings_mgc(l, bindings, 0, fn);
  let_body_mgc(l, args->cdr, discard, fn);
  GCPOP(1);
}

static int letstar_bindings_mgc(location l, struct list *bindings, fncode fn)
{
  int count = 0;

  GCPRO1(bindings);
  for (; TYPE(bindings, type_pair); bindings = bindings->cdr)
    {
      value binding = extract_location(bindings->car, &l);

      if (check_binding(l, binding, 0))
	{
	  count++;
	  GCPRO1(binding);
	  sgen_binding_init_mgc(l, binding, fn);
	  env_block_push(NULL);
	  sgen_binding_decl(l, binding, fn);
	  sgen_binding_assign_mgc(l, binding, fn);
	  GCPOP(1);
	}
    }
  if (bindings)
    log_error(l, "invalid bindings");
  GCPOP(1);

  return count;
}

static void compile_letstar_mgc(location l, struct list *args, bool discard, fncode fn)
{
  value bindings;
  int count;

  GCPRO1(args);
  env_block_push(NULL); // useless, but let_body_mgc has a pop
  bindings = extract_location(args->car, &l);
  count = letstar_bindings_mgc(l, bindings, fn);
  let_body_mgc(l, args->cdr, discard, fn);
  while (count--)
    env_block_pop();
  GCPOP(1);
}

static void letrec_bindings_mgc(location l, struct list *bindings, fncode fn)
{
  if (TYPE(bindings, type_pair))
    {
      value binding;
      int ok;

      binding = extract_location(bindings->car, &l);
      ok = check_binding(l, binding, 0) != NULL;

      GCPRO2(bindings, binding);
      if (ok)
	sgen_binding_decl(l, binding, fn);

      letrec_bindings_mgc(l, bindings->cdr, fn);

      if (ok)
	{
	  sgen_binding_init_mgc(l, binding, fn);
	  sgen_binding_assign_mgc(l, binding, fn);
	}
      GCPOP(2);
    }
  else if (bindings)
    log_error(l, "invalid bindings");
}

static void compile_letrec_mgc(location l, struct list *args, bool discard, fncode fn)
{
  value bindings;

  env_block_push(NULL);
  GCPRO1(args);
  bindings = extract_location(args->car, &l);
  letrec_bindings_mgc(l, bindings, fn);
  let_body_mgc(l, args->cdr, discard, fn);
  GCPOP(1);
}

static void do_var_update_mgc(location l, struct list *bindings, fncode fn)
{
  if (bindings)
    {
      GCPRO1(bindings);
      scheme_compile_mgc(l, nth(skip_location(bindings->car), 3), FALSE, fn);
      do_var_update_mgc(l, bindings->cdr, fn);
      sgen_binding_assign_mgc(l, skip_location(bindings->car), fn);
      GCPOP(1);
    }
}

static void compile_do_mgc(location l, struct list *args, bool discard, fncode fn)
{
  struct list *exitpart, *body, *bindings;
  int ok;
  location exitl = l;
  label looplab = new_label(fn), exitlab = new_label(fn), contlab = new_label(fn);

  env_block_push(NULL);
  GCPRO1(args);
  bindings = extract_location(args->car, &l);
  ok = let_bindings_mgc(l, bindings, 1, fn);
  set_label(looplab, fn);
  exitpart = extract_location(nth(args, 2), &exitl);
  if (list_length(exitpart) < 1)
    {
      ok = FALSE;
      log_error(exitl, "invalid do exit condition");
    }
  else
    sgen_condition_mgc(exitl, exitpart->car, FALSE,
		       exitlab, NULL, NULL, contlab, NULL, NULL, fn);
  body = nthtail(args, 3);
  set_label(contlab, fn);
  if (body)
    compile_block_mgc(l, body, TRUE, fn);
  if (ok)
    {
      bindings = extract_location(args->car, &l);
      do_var_update_mgc(l, bindings, fn);
    }
  branch(OPmba3, looplab, fn);
  set_label(exitlab, fn);
  if (ok)
    {
      exitpart = skip_location(nth(args, 2));
      if (exitpart->cdr)
	compile_begin_mgc(exitl, exitpart->cdr, discard, fn);
      else
	ins_undefined(discard, fn);
    }
  GCPOP(1);
}

struct logicaldata {
  struct list *args;
  label truelab, falselab, endlab;
  bool discard;
};

static void exit_logical(struct logicaldata *data, fncode fn)
{
  terminate(data->endlab, data->discard, fn);
}

static void continue_cond_mgc(location l, struct logicaldata *data, fncode fn);

static void cond_clause_true_mgc(location l, void *_data, fncode fn)
{
  struct logicaldata *data = _data;
  struct list *clause = skip_location(data->args->car);

  set_label(data->truelab, fn);
  compile_begin_mgc(l, clause->cdr, data->discard, fn);
  exit_logical(data, fn);
}

static void cond_clause_truecall_mgc(location l, void *_data, fncode fn)
{
  struct logicaldata *data = _data;

  entry_with_data(data->truelab, FALSE, fn);
  compile_call_mgc(l, nth(skip_location(data->args->car), 3), 1, data->discard, fn);
  exit_logical(data, fn);
}

static void cond_clause_cont_mgc(location l, void *_data, fncode fn)
{
  /* Copy the data as we're modifying args (there's no guarantee the
     true clauses won't be called after us) */
  struct logicaldata *olddata = _data;
  struct logicaldata newdata = *olddata;

  set_label(olddata->falselab, fn);
  newdata.args = olddata->args->cdr;
  GCPRO1(newdata.args);
  continue_cond_mgc(l, &newdata, fn);
  GCPOP(1);
}

static void continue_cond_mgc(location l, struct logicaldata *data, fncode fn) 
{
  int len;
  struct list *clause;

  data->truelab = new_label(fn);
  data->falselab = new_label(fn);

  if (!data->args)
    {
      ins_undefined(data->discard, fn);
      exit_logical(data, fn);
      return;
    }

  clause = extract_location(data->args->car, &l);
  len = list_length(clause);
  if (len >= 2)
    {
      struct list *body = clause->cdr;

      if (is_keyword(clause->car, "else"))
	{
	  if (data->args->cdr)
	    log_error(l, "else clause must come last");
	  compile_begin_mgc(l, body, data->discard, fn);
	  exit_logical(data, fn);
	}
      else if (is_keyword(body->car, "=>"))
	{
	  if (len != 3)
	    log_error(l, "invalid => clause in cond");
	  else
	    sgen_condition_mgc(l, clause->car, TRUE,
			       data->truelab, cond_clause_truecall_mgc, data,
			       data->falselab, cond_clause_cont_mgc, data, fn);
	}
      else /* regular clause */
	sgen_condition_mgc(l, clause->car, FALSE,
			   data->truelab, cond_clause_true_mgc, data,
			   data->falselab, cond_clause_cont_mgc, data, fn);
    }
  else
    log_error(l, "invalid cond clause");
}

static void compile_cond_mgc(location l, struct list *args, bool discard, fncode fn)
{
  struct logicaldata logicaldata;

  logicaldata.endlab = new_label(fn);
  logicaldata.args = args;
  logicaldata.discard = discard;
  GCPRO1(logicaldata.args);
  continue_cond_mgc(l, &logicaldata, fn);
  GCPOP(1);
  entry_with_data(logicaldata.endlab, discard, fn);
}

static void continue_and_mgc(location l, void *_data, fncode fn) 
{
  struct logicaldata *data = _data;

  if (!data->args->cdr) /* last clause */
    {
      scheme_compile_mgc(l, data->args->car, data->discard, fn);
      exit_logical(data, fn);
    }
  else
    {
      value clause = data->args->car;

      data->args = data->args->cdr;

      if (data->truelab)
	set_label(data->truelab, fn);
      data->truelab = new_label(fn);
      sgen_condition_mgc(l, clause, FALSE,
			 data->truelab, continue_and_mgc, data,
			 data->falselab, NULL, NULL, fn);
    }
}

static void compile_and_mgc(location l, struct list *args, bool discard, fncode fn)
{
  struct logicaldata logicaldata;

  if (args == NULL)
    {
      if (!discard)
	ins_constant(makebool(TRUE), fn);
      return;
    }

  logicaldata.truelab = NULL;
  logicaldata.falselab = new_label(fn);
  logicaldata.endlab = new_label(fn);
  logicaldata.args = args;
  logicaldata.discard = discard;
  GCPRO1(logicaldata.args);
  continue_and_mgc(l, &logicaldata, fn);
  GCPOP(1);
  set_label(logicaldata.falselab, fn);
  if (!discard)
    ins_constant(makebool(FALSE), fn);
  set_label(logicaldata.endlab, fn);
}

static void continue_or_mgc(location l, void *_data, fncode fn) 
{
  struct logicaldata *data = _data;

  if (!data->args->cdr) /* last clause */
    {
      scheme_compile_mgc(l, data->args->car, data->discard, fn);
      exit_logical(data, fn);
    }
  else
    {
      value clause = data->args->car;

      data->args = data->args->cdr;

      if (data->falselab)
	set_label(data->falselab, fn);
      data->falselab = new_label(fn);
      sgen_condition_mgc(l, clause, !data->discard,
			 data->endlab, NULL, NULL,
			 data->falselab, continue_or_mgc, data, fn);
    }
}

static void compile_or_mgc(location l, struct list *args, bool discard, fncode fn)
{
  struct logicaldata logicaldata;

  if (args == NULL)
    {
      if (!discard)
	ins_constant(makebool(FALSE), fn);
      return;
    }

  logicaldata.falselab = NULL;
  logicaldata.endlab = new_label(fn);
  logicaldata.args = args;
  logicaldata.discard = discard;
  GCPRO1(logicaldata.args);
  continue_or_mgc(l, &logicaldata, fn);
  GCPOP(1);
  entry_with_data(logicaldata.endlab, discard, fn);
}

#define CASEVARNAME ".case."
static void compile_case_mgc(location l, struct list *args, bool discard, fncode fn)
{
  label nextclause = NULL;
  label done = new_label(fn);

  env_block_push(NULL);
  env_declare(str2vlist(fnmemory(fn), l, CASEVARNAME));
  GCPRO1(args);
  scheme_compile_mgc(l, args->car, FALSE, fn);
  sgen_assign_mgc(l, CASEVARNAME, TRUE, fn);

  while (args->cdr)
    {
      struct list *clause, *datums;

      if (nextclause)
	set_label(nextclause, fn);
      nextclause = new_label(fn);

      args = args->cdr;
      clause = extract_location(args->car, &l);
      if (list_length(clause) < 2)
	log_error(l, "invalid case clause");
      else if (is_keyword(clause->car, "else"))
	{
	  if (args->cdr)
	    log_error(l, "else clause must be last in case");
	  compile_begin_mgc(l, clause->cdr, discard, fn);
	  terminate(done, discard, fn);
	}
      else if (list_length((datums = skip_location(clause->car))) < 0)
	log_error(l, "invalid case datums");
      else if (datums) /* empty datums is ok, but should be ignored */
	{
	  label match = new_label(fn);

	  GCPRO1(datums);
	  for (; datums; datums = datums->cdr)
	    {
	      scompile_recall(l, CASEVARNAME, fn);
	      ins_constant(filter_locations_mgc(datums->car), fn);
	      ins0(OPmeq, fn);
	      if (datums->cdr)
		branch(OPmbt3, match, fn);
	      else
		branch(OPmbf3, nextclause, fn);
	    }
	  GCPOP(1);
	  set_label(match, fn);
	  compile_begin_mgc(l, clause->cdr, discard, fn);
	  terminate(done, discard, fn);
	}
    }
  GCPOP(1);
  set_label(nextclause, fn);
  ins_undefined(discard, fn);
  set_label(done, fn);
  env_block_pop();
}

static struct {
  const char *keyword;
  int nargs;
  void (*compile_mgc)(location l, struct list *args, bool discard, fncode fn);
  int maxargs;
} syntax[] = {
  { "quote", 1, compile_quote },
  { "lambda", -2, compile_lambda_mgc },
  { "begin", -1, compile_begin_mgc },
  { "if", -2, compile_if_mgc, 3 },
  { "set!", 2, compile_setb_mgc },
  { "define", -1, compile_define_mgc },
  { "let", -2, compile_let_mgc },
  { "let*", -2, compile_letstar_mgc },
  { "letrec", -2, compile_letrec_mgc },
  { "do", -2, compile_do_mgc },
  { "cond", -1, compile_cond_mgc },
  { "and", 0, compile_and_mgc },
  { "or", 0, compile_or_mgc },
  { "case", -2, compile_case_mgc },
};

static void compile_list_mgc(location l, struct list *list, bool discard, fncode fn)
{
  int nargs = list_length(list->cdr);

  if (nargs < 0)
    {
      log_error(l, "improper list");
      return;
    }

  if (TYPE(list->car, type_symbol))
    {
      struct string *name = ((struct symbol *)list->car)->name;
      int i;

      for (i = 0; i < sizeof syntax / sizeof *syntax; i++)
	if (!strcmp(name->str, syntax[i].keyword))
	  {
	    const char *plural_args = abs(syntax[i].nargs) == 1 ? "" : "s";

	    if (syntax[i].nargs > 0)
	      {
		if (nargs != syntax[i].nargs)
		  {
		    log_error(l, "%s expected %d argument%s",
			      syntax[i].keyword, syntax[i].nargs, plural_args);
		    return;
		  }
	      }
	    else if (syntax[i].nargs < 0)
	      {
		if (nargs < -syntax[i].nargs)
		  {
		    log_error(l, "%s expected at least %d argument%s",
			      syntax[i].keyword, -syntax[i].nargs, plural_args);
		    return;
		  }
		if (syntax[i].maxargs && nargs > syntax[i].maxargs)
		  {
		    log_error(l, "%s expected at most %d argument%s",
			      syntax[i].keyword, syntax[i].maxargs, plural_args);
		    return;
		  }
	      }
	    syntax[i].compile_mgc(l, list->cdr, discard, fn);
	    return;
	  }
    }
  if (nargs >= 16)
    log_error(l, "no more than 15 arguments allowed");

  GCPRO1(list);
  compile_args_mgc(l, list->cdr, fn);
  GCPOP(1);
  compile_call_mgc(l, list->car, nargs, discard, fn);
}

void scheme_compile_mgc(location l, value v, bool discard, fncode fn)
{
  if (INTEGERP(v))
    {
      if (!discard)
	ins_constant(v, fn);
      return;
    }
  else if (POINTERP(v))
    {
      switch (OBJTYPE(v))
	{
	case type_string:
	  if (!discard)
	    ins_constant(v, fn);
	  return;
	case type_pair:
	  v = extract_location(v, &l);
	  compile_list_mgc(l, v, discard, fn);
	  return;
	case type_symbol:
	  if (!discard)
	    scompile_recall(l, sym2str(fnmemory(fn), v), fn);
	  return;
	}
    }
  log_error(l, "invalid scheme expression");
}
