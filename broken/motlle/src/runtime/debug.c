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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/param.h>
#include <ctype.h>
#include "runtime/runtime.h"
#include "runtime/basic.h"
#include "mudio.h"
#include "global.h"
#include "alloc.h"
#include "interpret.h"

#ifdef MUME
#include "interact.h"
#include "struct.char.h"
#include "frontend.h"
#endif

static void show_function(struct closure *c);

OPERATION("help", help, "fn -> . Provides help on function fn", 1, (value v),
	  OP_LEAF)
{
  if (!TYPE(v, type_function))
    mprintf(mudout, "This variable isn't executable");
  else if (FPRIMITIVEP(v))
    mputs(PRIMOP(globals, v)->help, mudout);
  else
    show_function(v);
  mputs(EOL, mudout);
  undefined();
}

TYPEDOP("help_string", help_string,
"fn -> s. Returns fn's help string, or false if none",
	1, (value v),
	OP_LEAF | OP_NOESCAPE, "f.S")
{
  TYPEIS(v, type_function);

  if (FPRIMITIVEP(v))
    return alloc_string(PRIMOP(globals, v)->help);
  else
    return ((struct closure *)v)->code->help;
}

TYPEDOP("defined_in", defined_in, 
"fn -> v. Returns information on where fn is defined (filename, lineno). \n\
Returns false for primitives",
	1, (value fn),
	OP_LEAF | OP_NOESCAPE, "f.v")
{
  TYPEIS(fn, type_function);

  if (FPRIMITIVEP(fn))
    return makebool(FALSE);
  else
    {
      struct closure *c = fn;
      struct vector *v;
      struct string *filename;
      u16 lineno;

      filename = c->code->filename;
      lineno = c->code->lineno;

      GCPRO1(filename);
      v = alloc_vector(2);
      GCPOP(1);
      v->data[0] = filename;
      v->data[1] = makeint(lineno);

      return v;
    }
}

TYPEDOP("function_name", function_name, 
"fn -> s. Returns name of fn if available, false otherwise",
	1, (value fn),
	OP_LEAF | OP_NOESCAPE, "f.x")
{
  TYPEIS(fn, type_function);

  if (FPRIMITIVEP(fn))
    return alloc_string(PRIMOP(globals, fn)->name);
  else
    {
      struct closure *c = fn;

      return c->code->varname;
    }
}

static void show_function(struct closure *c)
{
  struct code *code = c->code;

  if (code->help) mprint(mudout, prt_display, code->help);
  else mputs("undocumented", mudout);
  mputs(" [", mudout);
  mprint(mudout, prt_display, code->filename);
  mprintf(mudout, ":%d", code->lineno);
  mputs("]", mudout);
}

OPERATION("profile", profile, 
"fn -> x. Returns profiling information for function fn: \n\
(#calls #instructions) for mudlle functions,\n\
#calls for primitives",
	  1, (value fn),
	  OP_LEAF)
{
  struct list *tmp;
  struct code *c;

  TYPEIS(fn, type_function);

  if (FPRIMITIVEP(fn))
    return makeint(PRIMOP(globals, fn)->call_count);
  else
    {
      c = ((struct closure *)fn)->code;

      GCPRO1(c);
      tmp = alloc_list(makeint(c->instruction_count), NULL);
      tmp = alloc_list(makeint(c->call_count), tmp);
      GCPOP(1);

      return tmp;
    }
}

static int instr(char *s1, char *in)
{
  while (*in)
    {
      char *s = s1, *ins = in;

      while (*s && tolower(*s) == tolower(*ins)) { s++; ins++; }
      if (!*s) return TRUE;
      in++;
    }
  return FALSE;
}

OPERATION("apropos", apropos, 
"s -> . Finds all global variables whose name contains substring s and\n\
prints them (with help)",
	  1, (struct string *s),
	  OP_LEAF)
{
  struct list *lglobals;

  TYPEIS(s, type_string);

  GCPRO1(s);
  lglobals = global_list(globals);
  GCPRO1(lglobals);
  while (lglobals)
    {
      struct symbol *sym = lglobals->car;

      if (instr(s->str, sym->name->str))
	{
	  value v = GVAR(globals, intval(sym->data));

	  GCPRO1(v);
	  mprint(mudout, prt_display, sym->name);
	  mputs(EOL "  ", mudout);
	  if (TYPE(v, type_function))
	    if (FPRIMITIVEP(v))
	      {
		struct primitive_ext *op = PRIMOP(globals, v);

		if (op->help) 
		  mprintf(mudout, "Primitive: %s" EOL, op->help);
		else mputs("Undocumented primitive" EOL, mudout);
	      }
	    else
	      {
		mputs("Function: ", mudout);
		show_function(v);
		mputs(EOL, mudout);
	      }
	  else
	    mprintf(mudout, "Variable" EOL);
	  GCPOP(1);
	  
	}
      lglobals = lglobals->cdr;
    }
  GCPOP(2);
  undefined();
}

#ifndef MUME
OPERATION("quit", quit, " -> . Exit mudlle", 0, (void),
	  0)
{
  exit(0);
}
#endif

#ifdef GCSTATS
OPERATION("gcstats", gcstats, " -> l. Returns GC statistics", 0, (void),
	  OP_LEAF)
{
  struct gcstats stats;
  struct vector *gen0, *gen1, *last, *v;
  int i;

  stats = gcstats;

  gen0 = alloc_vector(2 * last_type);
  GCPRO1(gen0);
  gen1 = alloc_vector(2 * last_type);
  GCPRO1(gen1);
  last = alloc_vector(2 * last_type);
  GCPRO1(last);
  for (i = 0; i < last_type; i++)
    {
      last->data[2 * i] = makeint(stats.lnb[i]);
      last->data[2 * i + 1] = makeint(stats.lsizes[i]);
      gen0->data[2 * i] = makeint(stats.g0nb[i]);
      gen0->data[2 * i + 1] = makeint(stats.g0sizes[i]);
      gen1->data[2 * i] = makeint(stats.g1nb[i]);
      gen1->data[2 * i + 1] = makeint(stats.g1sizes[i]);
    }
  v = alloc_vector(8);
  v->data[0] = makeint(stats.minor_count);
  v->data[1] = makeint(stats.major_count);
  v->data[2] = makeint(stats.size);
  v->data[3] = makeint(stats.usage_minor);
  v->data[4] = makeint(stats.usage_major);
  v->data[5] = last;
  v->data[6] = gen0;
  v->data[7] = gen1;

  GCPOP(3);

  return v;
}

OPERATION("reset_gcstats!", reset_gcstatsb, 
" -> . Reset short GC statistics", 0, (void),
	  OP_LEAF | OP_NOALLOC)
{
  memset(gcstats.anb, 0, sizeof gcstats.anb);
  memset(gcstats.asizes, 0, sizeof gcstats.asizes);
  undefined();
}

OPERATION("short_gcstats", short_gcstats, " -> l. Returns short GC statistics",
	  0, (void),
	  OP_LEAF)
{
  struct gcstats stats = gcstats;
  struct vector *v = alloc_vector(2 * last_type);
  int i;

  for (i = 0; i < last_type; ++i)
    {
      v->data[2 * i] = makeint(stats.anb[i]);
      v->data[2 * i + 1] = makeint(stats.asizes[i]);
    }

  return v;
}
#endif
