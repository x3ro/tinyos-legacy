/*
 * Copyright (c) 1993-1999 David Gay and Gustav H�llberg
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

#include <stdarg.h>
#include <string.h>
#include "mudlle.h"
#include "tree.h"
#include "compile.h"
#include "error.h"
#include "utils.h"
#include "env.h"
#include "lexer.h"

location get_location(void)
{
  return lexloc;
}

mfile new_file(block_t heap, enum file_class vclass, const char *name,
	       vlist imports, vlist defines, vlist reads, vlist writes,
	       clist body)
{
  mfile newp = allocate(heap, sizeof *newp);

  newp->vclass = vclass;
  newp->name = name;
  newp->imports = imports;
  newp->defines = defines;
  newp->reads = reads;
  newp->writes = writes;
  newp->body = body;

  return newp;
}

function new_function(block_t heap, mtype type, const char *help, vlist args,
		      component avalue, location l)
{
  function newp = allocate(heap, sizeof *newp);

  newp->type = type;
  newp->help = help;
  newp->args = args;
  newp->varargs = FALSE;
  newp->value = avalue;
  newp->l = l;
  newp->varname = NULL;

  return newp;
}

function new_vfunction(block_t heap, mtype type, const char *help,
		       const char *arg, component avalue, location l)
{
  function newp = allocate(heap, sizeof *newp);

  newp->type = type;
  newp->help = help;
  /* using type_vector implies a useless type check */
  newp->args = new_vlist(heap, arg, stype_any, NULL, NULL);
  newp->varargs = TRUE;
  newp->value = avalue;
  newp->l = l;
  newp->varname = NULL;

  return newp;
}

block new_codeblock(block_t heap, vlist locals, clist sequence)
{
  block newp = allocate(heap, sizeof *newp);

  newp->l = get_location();
  newp->locals = locals;
  newp->sequence = sequence;

  return newp;
}

clist new_clist(block_t heap, component c, clist next)
{
  clist newp = allocate(heap, sizeof *newp);

  newp->next = next;
  newp->c = c;

  return newp;
}

cstlist new_cstlist(block_t heap, constant cst, cstlist next)
{
  cstlist newp = allocate(heap, sizeof *newp);

  newp->next = next;
  newp->cst = cst;

  return newp;
}

vlist new_vlist(block_t heap, const char *var, mtype type, component init,
		vlist next)
{
  vlist newp = allocate(heap, sizeof *newp);

  newp->l = get_location();
  newp->next = next;
  newp->var = var;
  newp->type = type;
  newp->init = init;

  return newp;
}

cstpair new_cstpair(block_t heap, constant cst1, constant cst2)
{
  cstpair newp = allocate(heap, sizeof *newp);

  newp->cst1 = cst1;
  newp->cst2 = cst2;
  
  return newp;
}

constant new_constant(block_t heap, enum constant_class vclass, ...)
{
  va_list args;
  constant newp = allocate(heap, sizeof *newp);

  newp->vclass = vclass;
  newp->loc.filename = NULL;
  newp->loc.lineno = 0;
  va_start(args, vclass);
  switch (vclass)
    {
    case cst_int:
      newp->u.integer = va_arg(args, int);
      break;
    case cst_string: case cst_gsymbol:
      newp->u.string = va_arg(args, const char *);
      break;
    case cst_list: 
      newp->loc = va_arg(args, location);
      /* fall through */
    case cst_array: case cst_table:
      newp->u.constants = va_arg(args, cstlist);
      break;
    case cst_quote:
      newp->loc = va_arg(args, location);
      newp->u.constant = va_arg(args, constant);
      break;
    case cst_float:
      newp->u.mudlle_float = va_arg(args, double);
      break;
    case cst_symbol:
      newp->u.constpair = va_arg(args, cstpair);
      break;
    default: assert(0);
    }
  va_end(args);
  return newp;
}

static clist make_clist(block_t heap, va_list args)
{
  int count;
  clist first = NULL, *scan = &first;

  for (count = va_arg(args, int); count > 0; count--)
    {
      *scan = new_clist(heap, va_arg(args, component), NULL);
      scan = &(*scan)->next;
    }
  return first;
}
  
component new_component(block_t heap, enum component_class vclass, ...)
{
  va_list args;
  component newp = allocate(heap, sizeof *newp);

  newp->l = get_location();
  newp->vclass = vclass;
  va_start(args, vclass);
  switch (vclass)
    {
    case c_assign: 
      newp->u.assign.symbol = va_arg(args, const char *);
      newp->u.assign.value = va_arg(args, component);
      break;
    case c_recall:
      newp->u.recall = va_arg(args, const char *);
      break;
    case c_constant:
      newp->u.cst = va_arg(args, constant);
      break;
    case c_scheme:
      newp->u.cst = va_arg(args, constant);
      break;
    case c_closure:
      newp->u.closure = va_arg(args, function);
      break;
    case c_block:
      newp->u.blk = va_arg(args, block);
      break;
    case c_execute:
      newp->u.execute = va_arg(args, clist);
      break;
    case c_builtin:
      newp->u.builtin.fn = va_arg(args, unsigned int);
      newp->u.builtin.args = make_clist(heap, args);
      break;
    case c_labeled: case c_exit:
      newp->u.labeled.name = va_arg(args, const char *);
      newp->u.labeled.expression = va_arg(args, component);
      break;
    case c_continue:
      newp->u.labeled.name = va_arg(args, const char *);
      break;
    case c_decl:
      newp->u.decls = va_arg(args, vlist);
      break;
    default: assert(0);
    }
  va_end(args);
  return newp;
}

pattern new_pattern_constant(block_t heap, constant c)
{
  pattern ap = allocate(heap, sizeof *ap);
  ap->vclass = pat_const;
  ap->u.constval = c;
  return ap;
}

pattern new_pattern_expression(block_t heap, component c)
{
  pattern ap = allocate(heap, sizeof *ap);
  ap->vclass = pat_expr;
  ap->u.expr = c;
  return ap;
}

pattern new_pattern_sink(block_t heap)
{
  pattern ap = allocate(heap, sizeof *ap);
  ap->vclass = pat_sink;
  return ap;
}

pattern new_pattern_symbol(block_t heap, const char *sym, mtype type)
{
  pattern ap = allocate(heap, sizeof *ap);
  ap->vclass = pat_symbol;
  ap->u.sym.name = sym;
  ap->u.sym.type = type;
  return ap;
}

pattern new_pattern_compound(block_t heap, 
					      enum pattern_class class,
					      patternlist list,
					      int ellipsis)
{
  pattern ap = allocate(heap, sizeof *ap);
  ap->vclass = class;
  ap->u.l.patlist = list;
  ap->u.l.ellipsis = ellipsis;
  return ap;
}

patternlist new_pattern_list(block_t heap, 
					      pattern pat,
					      patternlist tail)
{
  patternlist apl = allocate(heap, sizeof *apl);
  apl->next = tail;
  apl->pat = pat;
  return apl;
}

matchnodelist new_match_list(block_t heap, matchnode node, matchnodelist tail)
{
  matchnodelist ml = allocate(heap, sizeof *ml);
  ml->next = tail;
  ml->match = node;
  return ml;
}

matchnode new_matchnode(block_t heap, matchcond cond, clist body)
{
  matchnode nd = allocate(heap, sizeof *nd);
  nd->conditions = cond;
  nd->body = body;
  return nd;
}

matchcond new_matchcond(block_t heap, pattern pat, component cond, 
			 matchcond next)
{
  matchcond nd = allocate(heap, sizeof *nd);
  nd->pattern = pat;
  nd->condition = cond;
  nd->next = next;
  return nd;
}

clist append_clist(clist l1, clist l2)
{
  clist last;

  if (!l1) return l2;
  if (!l2) return l1;

  for (last = l1; last->next; last = last->next) ;
  last->next = l2;

  return l1;
}

clist reverse_clist(clist l)
{
  clist prev = NULL;

  while (l)
    {
      clist next = l->next;
      
      l->next = prev;
      prev = l;
      l = next;
    }
  return prev;
}

cstlist reverse_cstlist(cstlist l)
{
  cstlist prev = NULL;

  while (l)
    {
      cstlist next = l->next;
      
      l->next = prev;
      prev = l;
      l = next;
    }
  return prev;
}

vlist append_vlist(vlist l1, vlist l2)
{
  vlist last;

  if (!l1) return l2;
  if (!l2) return l1;

  for (last = l1; last->next; last = last->next) ;
  last->next = l2;

  return l1;
}

vlist reverse_vlist(vlist l)
{
  vlist prev = NULL;

  while (l)
    {
      vlist next = l->next;
      
      l->next = prev;
      prev = l;
      l = next;
    }
  return prev;
}

vlist find_vlist(vlist l, const char *name)
{
  for (; l; l = l->next)
    if (!strcmp(l->var, name))
      return l;
  return NULL;
}

/* Make a mudlle rep of a parse tree */
static value mudlle_parse_component(component c);

static value mudlle_vlist(vlist vars)
{
  value l = NULL;
  struct string *s;

  vars = reverse_vlist(vars);
  GCPRO1(l);
  while (vars)
    {
      value t;

      s = alloc_string(vars->var);
      t = alloc_list(s, makeint(vars->type));
      l = alloc_list(t, l);
      vars = vars->next;
    }
  GCPOP(1);
  return l;
}

static value mudlle_clist(clist exprs)
{
  value l = NULL;
  value c;

  exprs = reverse_clist(exprs);
  GCPRO1(l);
  while (exprs)
    {
      c = mudlle_parse_component(exprs->c);
      l = alloc_list(c, l);
      exprs = exprs->next;
    }
  GCPOP(1);
  return l;
}

static value mudlle_parse_component(component c)
{
  struct vector *mc;
  static char msize[] = { 2, 1, 1, 7, 1, 2, 2, 2, 2 };
  struct string *sym;
  value val;
  function f;

  mc = alloc_vector(msize[c->vclass] + 1);
  mc->data[0] = makeint(c->vclass);
  GCPRO1(mc);

  switch (c->vclass)
    {
    case c_assign:
      sym = alloc_string(c->u.assign.symbol);
      mc->data[1] = sym;
      val = mudlle_parse_component(c->u.assign.value);
      mc->data[2] = val;
      break;

    case c_recall:
      sym = alloc_string(c->u.recall);
      mc->data[1] = sym;
      break;

    case c_constant: case c_scheme:
      val = make_constant(c->u.cst, FALSE, NULL);
      mc->data[1] = val;
      break;

    case c_closure:
      f = c->u.closure;
      mc->data[1] = makeint(f->type);
      val = f->help ? alloc_string(f->help) : NULL;
      mc->data[2] = val;
      val = mudlle_vlist(f->args);
      mc->data[3] = val;
      mc->data[4] = makeint(f->varargs);
      val = mudlle_parse_component(f->value);
      mc->data[5] = val;
      mc->data[6] = makeint(f->l.lineno);
      val = make_filename(f->l.filename);
      mc->data[7] = val;
      break;

    case c_execute:
      val = mudlle_clist(c->u.execute);
      mc->data[1] = val;
      break;

    case c_builtin:
      mc->data[1] = makeint(c->u.builtin.fn);
      val = mudlle_clist(c->u.builtin.args);
      mc->data[2] = val;
      break;

    case c_block:
      val = mudlle_vlist(c->u.blk->locals);
      mc->data[1] = val;
      val = mudlle_clist(c->u.blk->sequence);
      mc->data[2] = val;
      break;

    case c_labeled: case c_exit:
      if (c->u.labeled.name) val = alloc_string(c->u.labeled.name);
      else val = NULL;
      mc->data[1] = val;
      val = mudlle_parse_component(c->u.labeled.expression);
      mc->data[2] = val;
      break;
      
    default:
      assert(0);
    }

  GCPOP(1);
  return mc;
}

value mudlle_parse(block_t heap, mfile f)
{
  struct vector *file = alloc_vector(7);
  value tmp;

  GCPRO1(file);
  file->data[0] = makeint(f->vclass);
  tmp = f->name ? alloc_string(f->name) : makebool(FALSE);
  file->data[1] = tmp;
  tmp = mudlle_vlist(f->imports);
  file->data[2] = tmp;
  tmp = mudlle_vlist(f->defines);
  file->data[3] = tmp;
  tmp = mudlle_vlist(f->reads);
  file->data[4] = tmp;
  tmp = mudlle_vlist(f->writes);
  file->data[5] = tmp;
  tmp = mudlle_parse_component(new_component(heap, c_block, f->body));
  file->data[6] = tmp;
  GCPOP(1);

  return file;
}

#ifdef PRINT_CODE
static void print_constant(FILE *f, constant c);

static void print_list(FILE *f, cstlist l, int has_tail)
{
  int first = TRUE;

  while (l)
    {
      if (!first) fprintf(f, " ");
      print_constant(f, l->cst);
      if (first) fprintf(f, " .");
      first = FALSE;
      l = l->next;
    }
}

static void print_vlist(FILE *f, vlist l)
{
  int first = TRUE;

  while (l)
    {
      if (!first) fprintf(f, ", ");
      first = FALSE;
      if (l->type != stype_any) fprintf(f, "%d ", l->type);
      fputs(l->var, f);
      l = l->next;
    }
}

static void print_constant(FILE *f, constant c)
{
  switch (c->vclass)
    {
    case cst_int:
      fprintf(f, "%d", c->u.integer);
      break;
    case cst_string:
      fprintf(f, "\"%s\"" , c->u.string);
      break;
    case cst_gsymbol:
      fprintf(f, "`%s'" , c->u.string);
      break;
    case cst_float:
      fprintf(f, "%f", c->u.mudlle_float);
      break;
    case cst_quote:
      fprintf(f, "'");
      print_constant(f, c->u.constant);
      break;
    case cst_list:
      fprintf(f, "(");
      print_list(f, c->u.constants, 1);
      fprintf(f, ")");
      break;
    case cst_array:
      fprintf(f, "#(");
      print_list(f, c->u.constants, 0);
      fprintf(f, ")");
      break;
    default: assert(0);
    }
}

static void print_component(FILE *f, component c);

static void print_block(FILE *f, block c)
{
  vlist vars = c->locals;
  clist sequence = c->sequence;

  fprintf(f, "[ ");
  if (vars)
    {
      print_vlist(f, vars);
      fprintf(f, "| ");
    }
  while (sequence)
    {
      print_component(f, sequence->c);
      fprintf(f, " ");
      sequence = sequence->next;
    }
  fprintf(f, "]");
}

static void print_clist(FILE *f, clist sequence)
{
  while (sequence)
    {
      fprintf(f, ", ");
      print_component(f, sequence->c);
      sequence = sequence->next;
    }
}

static void print_function(FILE *f, function fn)
{
  if (fn->help) fprintf(f, "fn \"%s\" (", fn->help);
  else fprintf(f, "fn (");
  print_vlist(f, fn->args);
  fprintf(f, ") ");
  print_component(f, fn->value);
}

static void print_component(FILE *f, component c)
{
  switch (c->vclass)
    {
    case c_assign:
      fprintf(f, "%s=", c->u.assign.symbol);
      print_component(f, c->u.assign.value);
      break;
    case c_recall:
      fprintf(f, "%s", c->u.recall);
      break;
    case c_execute:
      fprintf(f, "exec(");
      print_component(f, c->u.execute->c);
      print_clist(f, c->u.execute->next);
      fprintf(f, ")");
      break;
    case c_builtin:
      fprintf(f, "builtin(%d", c->u.builtin.fn);
      print_clist(f, c->u.builtin.args);
      fprintf(f, ")");
      break;
    case c_constant:
      print_constant(f, c->u.cst);
      break;
    case c_scheme:
      fprintf(f, "scheme ");
      print_constant(f, c->u.cst);
      break;
    case c_closure:
      print_function(f, c->u.closure);
      break;
    case c_block:
      print_block(f, c->u.blk);
      break;
    case c_labeled:
      fprintf(f, "<%s>", c->u.labeled.name);
      print_component(f, c->u.labeled.expression);
      break;
    case c_exit:
      if (c->u.labeled.name) fprintf(f, "exit(<%s>,", c->u.labeled.name);
      else fprintf(f, "exit(");
      print_component(f, c->u.labeled.expression);
      fprintf(f, ")");
      break;
    default: assert(0);
    }
}

void print_file(FILE *out, mfile f)
{
  static const char *fnames[] = { "", "module", "library" };

  fputs(fnames[f->vclass], out);
  if (f->name) fprintf(out, " %s\n", f->name);
  if (f->imports)
    {
      fprintf(out, "imports "); 
      print_vlist(out, f->imports);
      fprintf(out, "\n");
    }
  if (f->defines)
    {
      fprintf(out, "defines "); 
      print_vlist(out, f->defines);
      fprintf(out, "\n");
    }
  if (f->reads)
    {
      fprintf(out, "reads "); 
      print_vlist(out, f->reads);
      fprintf(out, "\n");
    }
  if (f->writes)
    {
      fprintf(out, "writes "); 
      print_vlist(out, f->writes);
      fprintf(out, "\n");
    }
  {
    block_t oops = new_block();

    print_component(out, new_component(oops, c_block, f->body));
    free_block(oops);
  }
}

#endif

static char *heap_allocate_string(block_t heap, const char *s)
{
  char *r = allocate(heap, strlen(s) + 1);
  strcpy(r, s);
  return r;
}

static block_t build_heap;

static vlist apc_symbols;

static clist build_clist(int n, ...)
{
  va_list args;
  clist res = NULL;

  va_start(args, n);
  while (n-- > 0)
    res = new_clist(build_heap, va_arg(args, component), res);
  va_end(args);

  return reverse_clist(res);
}

static component build_int_component(ivalue n)
{
  return new_component(build_heap, c_constant, 
		       new_constant(build_heap, cst_int, n));
}

static component build_string_component(const char *s) UNUSED;

static component build_string_component(const char *s)
{
  return new_component(build_heap, c_constant,
		       new_constant(build_heap, cst_string, s));
}

static component build_assign(const char *var, component val)
{
  return new_component(build_heap, c_assign, var, val);
}

static component build_recall(const char *var)
{
  return new_component(build_heap, c_recall, var);
}

static component build_exec(component f, int n, ...)
{
  va_list args;
  clist res = new_clist(build_heap, f, NULL);

  va_start(args, n);
  while (n--)
    res = new_clist(build_heap, va_arg(args, component), res);
  va_end(args);

  return new_component(build_heap, c_execute, reverse_clist(res));
}

static vlist build_vlist(int n, ...)
{
  va_list args;
  vlist res = NULL;

  va_start(args, n);
  while (n--)
    {
      const char *s = va_arg(args, const char *);
      mtype type = va_arg(args, mtype);
      res = new_vlist(build_heap, s, type, NULL, res);
    }

  va_end(args);
  return res;
}

static component build_logic_and(component e1, component e2)
{
  if (e2 == NULL || e2 == component_true)
    return e1;
  else if (e1 == NULL || e1 == component_true)
    return e2;
  else
    return new_component(build_heap, c_builtin, b_sc_and, 2, e1, e2);
}

static component build_logic_or(component e1, component e2)
{
  if (e2 == NULL || e2 == component_false)
    return e1;
  else if (e1 == NULL || e1 == component_false)
    return e2;
  else
    return new_component(build_heap, c_builtin, b_sc_or, 2, e1, e2);
}

static component build_binop(int op, component e1, component e2)
{
  return new_component(build_heap, c_builtin, op, 2, e1, e2);
}

static component build_unop(int op, component e)
{
  return new_component(build_heap, c_builtin, op, 1, e);
}

static component build_codeblock(vlist vl, clist code)
{
  return new_component(build_heap, c_block, 
		       new_codeblock(build_heap, vl, code));
}

static component build_reference(component x, component idx) UNUSED;

static component build_reference(component x, component idx)
{
  return new_component(build_heap, c_builtin, b_ref, 2, x, idx);
}

static component build_const_comparison(constant cst, component e)
{
  switch (cst->vclass) {
  case cst_list:
    /* we only want NULLs here - fallthrough */
    assert(cst->u.constants == NULL);
  case cst_int:
    return build_binop(b_eq, e,
		       new_component(build_heap, c_constant, cst));
  default:
    return build_exec(build_recall("=>"), 2, 
		      new_component(build_heap, c_constant, cst), e);
  }
}

static component build_typecheck(component e, mtype type)
{
  const char *f;

  switch (type) {
  case type_integer: f = "integer?"; break;
  case type_string: f = "string?"; break;
  case type_vector: f = "vector?"; break;
  case type_pair: f = "pair?"; break;
  case type_symbol: f = "symbol?"; break;
  case type_table: f = "table?"; break;
  case type_null: 
    return build_binop(b_eq, e,
		       new_component(build_heap, c_constant, 
				     new_constant(build_heap, cst_list, get_location(), NULL)));
  case stype_none:
    return component_false;
  case stype_any:
    return component_true;
  default:
    assert(0);
  }
  return build_exec(build_recall(f), 1, e);
}

static component build_match_block(pattern pat, component e,
				   int level)
{
  switch (pat->vclass) {
  case pat_sink:
    return component_true;
  case pat_symbol:
    {
      vlist sym;
      
      for (sym = apc_symbols; sym; sym = sym->next)
	if (strcasecmp(sym->var, pat->u.sym.name) == 0)
	  {
	    log_error(sym->l, "repeated variable name in match pattern (%s)", 
		      pat->u.sym.name);
	    return NULL;
	  }

      apc_symbols = new_vlist(build_heap, pat->u.sym.name, stype_any, NULL,
			      apc_symbols);

      return build_codeblock
	(NULL,
	 build_clist(2,
		     build_assign(pat->u.sym.name, e),
		     build_typecheck(build_recall(pat->u.sym.name),
				     pat->u.sym.type)));
    }
  case pat_const:
    return build_const_comparison(pat->u.constval, e);
  case pat_array:
    {
      /*
       *  [
       *    | tmp |
       *    tmp = <expression>;
       *    (vector?(tmp) &&
       *     vector_length(tmp) == vector_length(<pattern>) &&
       *     tmp[0] == <pattern>[0] &&
       *          :
       *     tmp[N] == <pattern>[N])
       *  ]
       */

      clist code;
      component check = NULL;
      int vlen, n;
      patternlist apl = pat->u.l.patlist;

      char buf[16], *tmpname;
      
      sprintf(buf, "~%d", level);
      tmpname = heap_allocate_string(build_heap, buf);

      code = build_clist(1, build_assign(tmpname, e));

      for (vlen = 0, apl = pat->u.l.patlist; apl; apl = apl->next)
	++vlen;

      for (n = vlen, apl = pat->u.l.patlist; apl; apl = apl->next)
	{
	  component c;

	  --n;
	  c = build_match_block
	    (apl->pat, 
	     new_component(build_heap, c_builtin, b_ref, 2,
			   build_recall(tmpname),
			   build_int_component(n)),
	     level + 1);

	  check = build_logic_and(c, check);
	}
      
      if (!(pat->u.l.ellipsis && vlen == 0))
	check = build_logic_and
	  (build_binop
	   (pat->u.l.ellipsis ? b_ge : b_eq,
	    build_exec(build_recall(GLOBAL_ENV_PREFIX "vector_length"), 1,
		       build_recall(tmpname)),
	    build_int_component(vlen)),
	   check);

      check = build_logic_and
	(build_exec(build_recall(GLOBAL_ENV_PREFIX "vector?"), 1,
		    build_recall(tmpname)),
	 check);

      code = new_clist(build_heap, check, code);

      return build_codeblock(build_vlist(1, tmpname, stype_any),
			     reverse_clist(code));
    }
  case pat_list:
    if (pat->u.l.patlist == NULL)
      return build_const_comparison
	(new_constant(build_heap, cst_list, get_location(), NULL), e);
    else
      {
	/*
	 *  [
	 *    | tmp |
	 *    tmp = <expression>;
	 *    pair?(tmp) &&
	 *    car(tmp) == car(<pattern>) &&
	 *      [
	 *        tmp = cdr(tmp); <pattern> = cdr(<pattern>);
	 *        pair?(tmp) &&
	 *        car(tmp) == car(<pattern>) &&
	 *          :
	 *          [                              \  this is done at
	 *            cdr(tmp) == cdr(<pattern>);  +- the last pair
	 *          ]                              /
	 *      ]
	 *  ]
	 */
	patternlist apl = pat->u.l.patlist;
	component check, getcdr;
	clist code;
	char buf[16], *tmpname;
	int first = TRUE;

	sprintf(buf, "~%d", level);
	tmpname = heap_allocate_string(build_heap, buf);

	code = build_clist(1, build_assign(tmpname, e));
	
	/* ~tmp = cdr(~tmp) */
	getcdr = build_exec(build_recall(GLOBAL_ENV_PREFIX "cdr"), 1, 
			    build_recall(tmpname));
	
	/* this will go last: compare the tail */
	if (apl->pat == NULL)
	  check = build_const_comparison
	    (new_constant(build_heap, cst_list, get_location(), NULL), getcdr);
	else
	  check = build_match_block(apl->pat, getcdr, level + 1);
	
	for (apl = apl->next; apl; apl = apl->next)
	  {
	    component c = build_binop
	      (b_sc_and,
	       build_exec(build_recall(GLOBAL_ENV_PREFIX "pair?"), 1, 
			  build_recall(tmpname)),
	       build_match_block
	       (apl->pat, 
		build_exec(build_recall(GLOBAL_ENV_PREFIX "car"), 1, 
			   build_recall(tmpname)),
		level + 1));
	    if (first)
	      first = FALSE;
	    else
	      {
		component movecdr;
		getcdr = build_exec(build_recall(GLOBAL_ENV_PREFIX "cdr"), 1, 
				    build_recall(tmpname));
		movecdr = build_assign(tmpname, getcdr);
		check = build_codeblock(NULL, build_clist(2, movecdr, check));
	      }
	    check = build_binop(b_sc_and, c, check);
	  }

	code = new_clist(build_heap, check, code);

	return build_codeblock(build_vlist(1, tmpname, stype_any),
			       reverse_clist(code));
      }
  case pat_expr:
    return build_exec(build_recall("=>"), 2, pat->u.expr, e);
  default:
    assert(0);
    return NULL;
  }
}

static component build_error(int error)
{
  return build_exec(build_recall(GLOBAL_ENV_PREFIX "error"), 1, 
		    build_int_component(error));
}

static bool cs1(vlist l1, vlist l2)
/* Effects: Checks that l1's symbols are a subset of l2's, report
     an error if they aren't
   Returns: TRUE if they aren't
*/
{
  for (; l1; l1 = l1->next)
    if (!find_vlist(l2, l1->var))
      {
	log_error(l2->l, "conflicting variables in case patterns");
	return TRUE;
      }
  return FALSE;
}

static bool compare_symbols(vlist l1, vlist l2)
/* Effects: Checks that l1 and l2 have the same set of symbols, report
     an error if they don't.
   Returns: TRUE if they don't
*/
{
  return cs1(l1, l2) || cs1(l2, l1);
}

component new_pattern_component(block_t heap, pattern pat, component e)
{
  build_heap = heap;
  apc_symbols = NULL;

  /* 
   *  Warning: if the match fails, this might leave only some of the variables 
   *  in the pattern filled. But it's a feature, right?
   */
  return new_component(build_heap, c_builtin, b_ifelse, 3,
		       build_match_block(pat, e, 0),
		       component_undefined,
		       build_error(error_no_match));
}

component new_match_component(block_t heap, component e, matchnodelist matches)
{
  vlist vl;
  clist code, mdefault;
  build_heap = heap;

  /*
   *   <~match> [
   *     | ~exp |
   *     
   *     ~exp = <match-expression>
   *     [                                       \
   *       | <pattern-variables> |                |
   *       if (<pattern-match> [&& <condition>])  +- repeat for each match node
   *         exit<~match> <pattern-expression>;   |
   *     ]                                       /
   *     false
   *   ]
   */

  vl = build_vlist(1, "~exp", stype_any);

  mdefault = build_clist(1, component_false);
  code = NULL;
  for (; matches; matches = matches->next)
    {
      component matchcode, body;
      matchcond conditions;
      vlist symbols = NULL;
      bool ok = TRUE;

      if (!matches->match->conditions) /* default */
	{
	  mdefault = matches->match->body;
	  continue;
	}

      matchcode = NULL;
      for (conditions = matches->match->conditions; conditions;
	   conditions = conditions->next)
	{
	  component match1;

	  apc_symbols = NULL;

	  match1 = build_match_block(conditions->pattern,
				     build_recall("~exp"), 0);
	  match1 = build_logic_and(match1, conditions->condition);
	  if (matchcode)
	    {
	      matchcode = build_logic_or(matchcode, match1);
	      /* suppress multiple pattern var errors */
	      ok = ok && compare_symbols(apc_symbols, symbols);
	    }
	  else
	    {
	      symbols = apc_symbols;
	      matchcode = match1;
	    }
	}
      body = new_component(build_heap, c_block,
			   new_codeblock(build_heap, NULL, matches->match->body));
      matchcode = new_component(build_heap, c_builtin, b_if, 2,
				matchcode,
				new_component(build_heap, c_exit, NULL,
					      body));

      code = new_clist(build_heap,
		       build_codeblock(apc_symbols, build_clist(1, matchcode)),
		       code);
    }
  code = new_clist(build_heap, build_assign("~exp", e),
		   append_clist(code, mdefault));

  return new_component(build_heap, c_labeled, NULL, 
		       build_codeblock(vl, code));
}

component new_xor_component(block_t heap, component e0, component e1)
{
  vlist vl = new_vlist(heap, "~xor", stype_any, NULL, NULL);
  clist cl;
  build_heap = heap;

  /* 
   *  [
   *    | ~xor |
   *    ~xor = !<exp1>;
   *    if (<exp0>) ~xor else !~xor;
   *  ]
   */

  cl = new_clist(heap,
		 new_component(heap, c_assign, "~xor",
			       build_unop(b_not, e1)),
		 NULL);
  cl = new_clist(heap,
		 new_component(heap, c_builtin,
			       b_ifelse, 3, e0,
			       build_recall("~xor"),
			       build_unop(b_not, build_recall("~xor"))),
		 cl);
    
  return new_component(heap, c_block,
		       new_codeblock(heap,
				     vl,
				     reverse_clist(cl)));
}

component new_postfix_inc_component(block_t heap, const char *var, int op)
{
  vlist vl = new_vlist(heap, "~tmp", stype_any, NULL, NULL);
  clist cl;
  build_heap = heap;

  /* 
   *  [
   *    | ~tmp |
   *    ~tmp = <var>;
   *    <var> = ~tmp + 1;
   *    ~tmp;
   *  ]
   */

  cl = new_clist(heap,
		 new_component(heap, c_assign, "~tmp",
			       build_recall(var)),
		 NULL);
  cl = new_clist(heap,
		 new_component(heap, c_assign, 
			       var, 
			       build_binop(op,
					   build_recall("~tmp"),
					   new_component(heap, c_constant,
							 new_constant(heap, cst_int, 1)))),
		 cl);
  cl = new_clist(heap,
		 build_recall("~tmp"),
		 cl);
  return new_component(heap, c_block,
		       new_codeblock(heap,
				     vl,
				     reverse_clist(cl)));
}
