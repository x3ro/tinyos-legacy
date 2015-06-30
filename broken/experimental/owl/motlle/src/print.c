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
#include "tree.h"
#include "compile.h"
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
#define FLOATSTRLEN 20

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

#define insu8() (*i++)
#define insi8() ((i8)insu8())
#define insu16() (byte1 = *i++, byte2 = *i++, (byte1 << 8) + byte2)
#define insi16() ((i16)insu16())

static instruction *print_branch(struct oport *f, instruction *i, u16 ofs,
				 const char *name, int encoding)
{
  u8 byte1, byte2;
  i16 offset;
  int size;
  instruction *old_i = i - 1;

  if (encoding == 0)
    {
      size = 1;
      offset = insi8();
    }
  else if (encoding == 7)
    {
      offset = insi16();
      size = 2;
    }
  else
    {
      size = 0;
      offset = encoding;
    }

  pprintf(f, "%s[%d] %d (to %u)\n", name, encoding, offset,
	  ofs + i - old_i + offset);

  return i;
}

static int write_instruction(struct oport *f, instruction *i, u16 ofs)
{
  u8 byte1, byte2;
  u8 op;
  i16 word1;
  int scan;

  instruction *old_i = i;
  const char *brname[] = { "", "(loop)", "(nz)", "(z)" };
  const char *builtin_names[last_builtin] =
    { NULL, NULL, "eq", "ne", "gt", "lt", "le", "ge", 
      "bitor", "bitxor", "bitand", "shift_left", "shift_right", 
      "add", "sub", "multiply", "divide", "remainder", "negate",
      "not", "bitnot", NULL, NULL, NULL, NULL, "ref", "set", "cons", NULL };

  op = insu8();

  pprintf(f, "%5d: ", ofs);
  switch (op)
    {
    case OPhalt: pprintf(f, "halt\n"); break;
    case OPmreadl: pprintf(f, "recall/l %u\n", insu8()); break;
    case OPmreadl3 ... OPmreadl3 + 7: pprintf(f, "recall/l3 %u\n", op - OPmreadl3); break;
    case OPmreadc: pprintf(f, "recall/c %u\n", insu8()); break;
    case OPmreadc3 ... OPmreadc3 + 7: pprintf(f, "recall/c3 %u\n", op - OPmreadc3); break;
    case OPmreadg: pprintf(f, "recall/g %u\n", insu16()); break;
    case OPmwritel: pprintf(f, "assign/l %u\n", insu8()); break;
    case OPmwritel3 ... OPmwritel3 + 7: pprintf(f, "assign/l3 %u\n", op - OPmwritel3); break;
    case OPmwritec: pprintf(f, "assign/c %u\n", insu8()); break;
    case OPmwriteg: pprintf(f, "assign/g %u\n", insu16()); break;
    case OPmwritedl: pprintf(f, "assignd/l %u\n", insu8()); break;
    case OPmwritedl3 ... OPmwritedl3 + 7: pprintf(f, "assignd/l3 %u\n", op - OPmwritedl3); break;
    case OPmwritedc: pprintf(f, "assignd/c %u\n", insu8()); break;
    case OPmwritedg: pprintf(f, "assignd/g %u\n", insu16()); break;
    case OPmvcheck4 ... OPmvcheck4 + 15: 
      pprintf(f, "vtypecheck %d /l %d\n", op - OPmvcheck4, insu8());
      break;
    case OPmscheck4 ... OPmscheck4 + 15: 
      pprintf(f, "stypecheck %d\n", op - OPmscheck4);
      break;
    case OPmreturn: pprintf(f, "return\n"); break;
    case OPmcst: pcst(f, i, "constant "); i += sizeof(value); break;
    case OPmint3 ... OPmint3 + 7:
      pprintf(f, "integer %d\n", op - OPmint3);
      break;
    case OPmundefined: pprintf(f, "undefined (42)\n"); break;
    case OPmclosure: 
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
    case OPmexec4 ... OPmexec4 + 15:
      pprintf(f, "execute %u\n", op - OPmexec4); break;
    case OPmexecg4 ... OPmexecg4 + 15:
      pprintf(f, "execute %u global %u\n", op - OPmexecg4, insu16()); break;
    case OPmexecprim6 ... OPmexecprim6 + 63:
      pprintf(f, "execute primitive %u\n", op - OPmexecprim6); break;
    case OPmpop: pprintf(f, "discard\n"); break;
    case OPmexitn: pprintf(f, "exit %u\n", insu8()); break;
    case OPmba3 ... OPmba3 + 7:
      i = print_branch(f, i, ofs, "ba3", op - OPmba3);
      break;
    case OPmbt3 ... OPmbt3 + 7:
      i = print_branch(f, i, ofs, "bt3", op - OPmbt3);
      break;
    case OPmbf3 ... OPmbf3 + 7:
      i = print_branch(f, i, ofs, "bf3", op - OPmbf3);
      break;
    case OPmclearl:
      pprintf(f, "clear/l %u\n", insu8());
      break;
    default:
      for (scan = 0; scan < last_builtin; scan++)
	if (op == builtin_ops[scan])
	  {
	    pprintf(f, "builtin_%s\n", builtin_names[scan]);
	    goto ret;
	  }
      pprintf(f, "Opcode %d\n", op);
      break;
    }
 ret:
  return i - old_i;
}

static void write_code(struct oport *f, struct code *c)
{
  u16 nbins, i;

  GCPRO2(f, c);
  nbins = code_length(c);
  if (c->varname)
    {
      write_string(f, prt_display, c->varname);
      pputs(": ", f);
    }
  pprintf(f, "Code[");
  write_string(f, prt_display, c->filename);
  pprintf(f, ":%u] %u bytes:\n", c->lineno, nbins);
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
      pprintf(f, "\nand %u variables are\n", nbvar);

      for (i = 0; i < nbvar; i++) 
	{
	  pprintf(f, "%u: ", i);
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

static void write_float(struct oport *f, struct mudlle_float *v)
{
  char buf[FLOATSTRLEN];

  snprintf(buf, FLOATSTRLEN, "%#g", v->d);
  pputs(buf, f);
}

static void _print_value(struct oport *f, prt_level level, value v, int toplev)
{
  const char *mtypename[last_type] = {
    "code", "null", "string", "vector", 
    "list", "OOPS", "integer", "function", 
    "variable", "symbol", "table", "output-port", 
    "float" };
  const char visible_in[][last_type] = {
    /* Display */ { 0, 0, 1, 1, /* code, null, string, vector */
		    1, 0, 1, 0, /* pair, dummy1, integer, function */
		    0, 1, 0, 0, /* variable, symbol, table, output-port */
		    1 },        /* float */
    /* Print */   { 0, 0, 1, 1, /* code, null, string, vector */
		    1, 0, 1, 0, /* pair, dummy1, integer, function */
		    0, 1, 0, 0, /* variable, symbol, table, output-port */
		    1 },        /* float */
    /* Examine */ { 1, 0, 1, 1, /* code, null, string, vector */
		    1, 0, 1, 1, /* pair, dummy1, integer, function */
		    1, 1, 1, 0, /* variable, symbol, table, output-port */
		    1 } };      /* float */

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
	  case type_float: write_float(f, v); break;
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
