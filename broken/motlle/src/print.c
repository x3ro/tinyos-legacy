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
#include <stddef.h>
#include <string.h>
#include <setjmp.h>
#include <stdlib.h>

#include "mudlle.h"
#include "print.h"
#include "types.h"
#include "table.h"
#include "objenv.h"
#include "code.h"
#include "primitives.h"
#include "global.h"
#ifdef MUME
#include "def.time.h"
#include "def.char.h"
#include "def.obj.h"
#include "struct.time.h"
#include "struct.char.h"
#include "struct.obj.h"
#include "macro.h"
#endif

#define MAX_PRINT_COUNT 400

static int prt_count;
jmp_buf print_complex;

static unsigned char writable_chars[256 / 8];
#define set_writable(c, ok) \
  do { if (ok) writable_chars[(c) >> 3] |= 1 << ((c) & 7); \
       else writable_chars[(c) >> 3] &= ~(1 << ((c) & 7)); } while(0)
#define writable(c) (writable_chars[(c) >> 3] & (1 << ((c) & 7)))

static void _print_value(struct oport *f, prt_level level, value v, int toplev);

static void write_string(struct oport *p, prt_level level, struct string *print)
{
  uvalue l = string_len(print);

  if (level == prt_display)
    pswrite(p, print, 0, l);
  else
    {
      unsigned char *str = (unsigned char *)alloca(l + 1);
      unsigned char *endstr;

      memcpy((char *)str, print->str, l + 1);
      GCPRO1(p);
      /* The NULL byte at the end doesn't count */
      endstr = str + l;

      pputc('"', p);
      while (str < endstr)
	{
	  unsigned char *pos = str;

	  while (pos < endstr && writable(*pos)) pos++;
	  opwrite(p, (char *)str, pos - str);
	  if (pos < endstr)	/* We stopped for a \ */
	    {
	      pputc('\\', p);
	      switch (*pos)
		{
		case '\\': case '"': pputc(*pos, p); break;
		case '\n': pputc('n', p); break;
		case '\r': pputc('r', p); break;
		case '\t': pputc('t', p); break;
		case '\f': pputc('f', p); break;
		default: pprintf(p, "%o", *pos); break;
		}
	      str = pos + 1;
	    }
	  else str = pos;
	}
      pputc('"', p);
      GCPOP(1);
    }
}

static void pcst(struct oport *f, instruction *i, char *insname)
{
  value cst = RINSCST(i);

  GCPRO1(cst);
  pprintf(f, insname);
  GCPOP(1);
  _print_value(f, prt_examine, cst, 0);
  pprintf(f, "\n");
}

static int write_instruction(struct oport *f, instruction *i, u16 ofs)
{
  u8 byte1, byte2;
  u8 op;
  i16 word1;

  instruction *old_i = i;
  const char *brname[] = { "", "(loop)", "(nz)", "(z)" };
  const char *builtin_names[] =
  { "eq", "ne", "gt", "lt", "le", "ge", "sub", "multiply", "divide",
    "remainder", "bitor", "bitxor", "bitand", "shift_left", "shift_right", 
    "ref", "set", "add", "negate", "bitnot", "not", "or", "and" };

#define insu8() (*i++)
#define insi8() ((i8)insu8())
#define insu16() (byte1 = *i++, byte2 = *i++, (byte1 << 8) + byte2)
#define insi16() ((i16)insu16())

  op = insu8();

  pprintf(f, "%5d: ", ofs);
  if (op >= op_recall && op <= op_assign + global_var)
    {
      const char *opname[] = { "recall", "assign" };
      const char *classname[] = { "local", "closure", "global" };

      if ((op - op_recall) %3 == global_var)
	pprintf(f, "%s[%s] %lu\n", opname[(op - op_recall) / 3],
		classname[(op - op_recall) % 3], insu16());
      else
	pprintf(f, "%s[%s] %lu\n", opname[(op - op_recall) / 3],
		classname[(op - op_recall) % 3], insu8());
    }
  else if (op >= op_first_builtin && op < op_typecheck)
    pprintf(f, "builtin_%s\n", builtin_names[op - op_first_builtin]);
  else if (op >= op_typecheck && op < op_typecheck + last_synthetic_type)
    pprintf(f, "typecheck %d [local] %d\n", op - op_typecheck, insu8());
  else switch (op)
    {
    case op_define: pprintf(f, "define\n"); break;
    case op_return: pprintf(f, "return\n"); break;
    case op_constant: pcst(f, i, "constant "); i += sizeof(value); break;
    case op_integer1: pprintf(f, "integer1 %d\n", insi8()); break;
    case op_closure: 
      {
	int nvars = insu8(), var;

	/* Must copy instructions as GC might occur */
	instruction *tempi = alloca(2 + sizeof(value) + nvars);
	memcpy(tempi, i - 2, 2 + sizeof(value) + nvars);
	old_i = tempi; i = tempi + 2;

	pprintf(f, "closure %u\n", nvars);

	for (var = 0; var < nvars; var++)
	  {
	    u8 varspec = insu8();
	    u8 whichvar = varspec >> 1;

	    pprintf(f, "         %s %d\n",
		    (varspec & 1) == local_var ? "localvar" : "closurevar",
		    whichvar);
	  }
	pcst(f, i, "         code ");

	i += sizeof(value);
	break;
      }
    case op_execute: pprintf(f, "execute %u\n", insu8()); break;
    case op_execute_global1: pprintf(f, "execute[global %u] 1\n", insu16()); break;
    case op_execute_global2: pprintf(f, "execute[global %u] 2\n", insu16()); break;
    case op_discard: pprintf(f, "discard\n"); break;
    case op_exit_n: pprintf(f, "exit %u\n", insu8()); break;
    case op_branch1: case op_branch_z1: case op_branch_nz1: case op_loop1: {
      i8 offset1 = insi8();
      pprintf(f, "branch%s %d (to %lu)\n", brname[(op - op_branch1) / 2], offset1,
	      ofs + i - old_i + offset1);
      break;
    }
    case op_branch2: case op_branch_z2: case op_branch_nz2: case op_loop2:
      word1 = insi16();
      pprintf(f, "wbranch%s %d (to %lu)\n", brname[(op - op_branch1) / 2], word1,
	      ofs + i - old_i + word1);
      break;
    case op_clear_local:
      pprintf(f, "clear[local] %lu\n", insu8());
      break;
    default: pprintf(f, "Opcode %d\n", op); break;
    }
  return i - old_i;
}

static void write_code(struct oport *f, struct code *c)
{
  u16 nbins, i;

  GCPRO2(f, c);
  nbins = code_length(c);
  pprintf(f, "Code %lu bytes:\n", nbins);
  i = 0;
  while (i < nbins)
    i += write_instruction(f, c->ins + i, i);

  pprintf(f, "\n%u locals, %u stack\n",
	  c->nb_locals, c->stkdepth);
  GCPOP(2);
}

static void write_closure(struct oport *f, prt_level level, struct closure *c)
{
  u8 nbvar = (c->o.size - offsetof(struct closure, variables)) / sizeof(value), i;

  GCPRO2(f, c);
  pputs("{fn-", f);
  print_fnname(f, c);
  pputs("}", f);

  if (level == prt_examine)
    {
      _print_value(f, prt_examine, c->code, 0);
      pprintf(f, "\nand %lu variables are\n", nbvar);

      for (i = 0; i < nbvar; i++) 
	{
	  pprintf(f, "%lu: ", i);
	  _print_value(f, prt_examine, c->variables[i], 0);
	  pprintf(f, "\n");
	}
    }
  GCPOP(2);
}

static void write_vector(struct oport *f, prt_level level, struct vector *v, 
			 int toplev)
{
  uvalue len = vector_len(v), i;

  GCPRO2(f, v);
  if (level != prt_display && toplev) pprintf(f, "'");
  pprintf(f, "[");
  for (i = 0; i < len; i++)
    {
      pputc(' ', f);
      _print_value(f, level, v->data[i], 0);
    }
  pprintf(f, " ]");
  GCPOP(2);
}

static void write_list(struct oport *f, prt_level level, struct list *v,
		       int toplev)
{
  GCPRO2(f, v);
  if (level != prt_display && toplev) 
    pputc('\'', f);
  pputc('(', f);
  do {
    _print_value(f, level, v->car, 0);
    if (!TYPE(v->cdr, type_pair)) break;
    pputc(' ', f);
    v = v->cdr;
  } while (1);
  
  if (v->cdr)
    {
      pputs(" . ", f);
      _print_value(f, level, v->cdr, 0);
    }
  pprintf(f, ")");
  GCPOP(2);
}

static struct oport *write_table_oport;
static prt_level write_table_level;

static void write_table_entry(struct symbol *s)
{
  pputc(' ', write_table_oport);
  write_string(write_table_oport, write_table_level, s->name);
  pputc('=', write_table_oport);
  _print_value(write_table_oport, write_table_level, s->data, 0);
}

static void write_table(struct oport *f, prt_level level, struct table *t,
			int toplev)
{
  if (level < prt_examine && table_entries(t) > 10)
    {
      pputs("{table}", f);
      return;
    }

  GCPRO2(f, t);
  if (level != prt_display && toplev) 
    pputc('\'', f);
  pputc('{', f);
  write_table_oport = f;
  write_table_level = level;
  table_foreach(t, write_table_entry);
  pputs(" }", f);
  GCPOP(2);
}

static void write_integer(struct oport *f, ivalue v)
{
  char buf[INTSTRLEN];

  pputs(int2str(buf, 10, (u32)v, TRUE), f);
}

static void _print_value(struct oport *f, prt_level level, value v, int toplev)
{
  const char *mtypename[last_type] = {
    "code", "function", "string", "vector", "list", "null", "variable", 
    "symbol", "table", "output-port", "integer" };
  const char visible_in[][last_type] = {
    /* Display */ { 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0 },
    /* Print */   { 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0 },
    /* Examine */ { 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0 } };

  if (prt_count++ > MAX_PRINT_COUNT) 
    runtime_error(internal_error_print_too_complex);

  if (INTEGERP(v)) write_integer(f, intval(v));
  else if (!v) pprintf(f, "null");
  else if (PRIMITIVEP(v))
    {
      if (level >= prt_print)
	pprintf(f, "{fn-%s}", PRIMOP(globals, v)->name);
      else
	pprintf(f, "{function}");
    }
  else
    {
      struct obj *obj = v;

      assert(obj->type < last_type);
      if (!visible_in[level][obj->type])
	pprintf(f, "{%s}", mtypename[obj->type]);
      else
	switch (obj->type)
	  {
	  default: assert(0);
	  case type_string: write_string(f, level, v); break;
	  case type_symbol:
	    {
	      struct symbol *sym = v;

	      GCPRO2(f, sym);
	      pprintf(f, "<");
	      write_string(f, level, sym->name);
	      pprintf(f, ",");
	      _print_value(f, level, sym->data, 0);
	      pprintf(f, ">");
	      GCPOP(2);
	      break;
	    }
	  case itype_code: write_code(f, v); break;
	  case type_function: write_closure(f, level, v); break; /* We've already exluded primitives */
	  case type_table: write_table(f, level, v, toplev); break;
	  case type_pair: write_list(f, level, v, toplev); break;
	  case type_vector: write_vector(f, level, v, toplev); break;
	  }
    }
}

struct do_output_closure
{
  struct oport *f;
  prt_level level;
  value v;
};

static void do_output(void *data)
{
  struct do_output_closure *c = data;
  struct oport *p;

  /* c->f, c->v protected in output_value */
  p = make_string_outputport();
  GCPRO1(p);
  prt_count = 0;
  _print_value(p, c->level, c->v, 1);
  port_append(c->f, p);
  opclose(p);
  GCPOP(1);
}  

void output_value(struct oport *f, prt_level level, value v)
{
  if (!f) return;
  /* Optimise common cases (avoid complexity check overhead) */
  if (INTEGERP(v)) write_integer(f, intval(v));
  else if (!v) pputs_cst("null", f);
  else if (TYPE(v, type_string)) write_string(f, level, v);
  else
    {
      struct do_output_closure c;
      int err;

      c.f = f; c.level = level; c.v = v;
      GCPRO2(c.f, c.v);
      err = protect(do_output, &c);
      GCPOP(2);

      if (err == internal_error_print_too_complex)
	pputs_cst("<complex>", c.f);
      else if (err >= 0)
	runtime_error(err);
    }
}

void print_fnname(struct oport *f, struct closure *c)
{
  GCPRO1(c);
  if (c->code->varname)
    write_string(f, prt_display, c->code->varname);
  else pputs("<fn>", f);
  pputs("[", f);
  write_string(f, prt_display, c->code->filename);
  if (c->code->lineno)
    pprintf(f, ":%d]", c->code->lineno);
  else
    pputs("]", f);
  GCPOP(1);
}

void print_init(void)
{
  unsigned int c;

  for (c = 32; c < 127; c++) set_writable(c, TRUE);
  set_writable('"', FALSE);
  set_writable('\\', FALSE);
  for (c = 160; c < 256; c++) set_writable(c, TRUE); 
}
