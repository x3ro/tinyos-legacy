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
#include <string.h>
#include <stddef.h>
#include "runtime/runtime.h"
#include "alloc.h"
#include "global.h"
#include "utils.h"
#include "mparser.h"
#include "lexer.h"
#include "calloc.h"
#include "module.h"
#include "call.h"
#include "dump.h"
#include "compile.h"
#include "this_machine.h"
#include "mate_machine.h"

static void is_gstate(struct global_state *gstate)
{
  /* Could use lots more checks on gstate... */
  TYPEIS(gstate, type_vector);
  if (vector_len(gstate) != 8)
    RUNTIME_ERROR(error_bad_type);
}

OPERATION("idebug", idebug, "n -> . Set internal debugging level",
	  1, (value lvl), OP_LEAF | OP_NOESCAPE)
{
  ISINT(lvl);
  debug_lvl = intval(lvl);
  undefined();
}

OPERATION("mudlle_parse", mudlle_parse, 
"s -> v. Parses a mudlle expression and returns a parse tree", 
	  1, (struct string *code), OP_LEAF | OP_NOESCAPE)
{
  mfile f;
  value parsed;
  block_t pmemory;

  TYPEIS(code, type_string);

  read_from_string(code->str, FALSE);
  pmemory = new_block();
  if ((f = parse(pmemory)))
    parsed = mudlle_parse(pmemory, f);
  else
    parsed = makebool(FALSE);

  free_block(pmemory);

  return parsed;
}

UNSAFEOP("mudlle_parse_file", mudlle_parse_file, 
"s1 s2 -> v. Parses a file s (nice name s2) and returns its parse tree",
	 2, (struct string *name, struct string *nicename),
	 OP_LEAF | OP_NOESCAPE)
{
  FILE *f;
  value parsed;
  char *fname;
  block_t pmemory;
  mfile mf;

  TYPEIS(name, type_string);
  TYPEIS(nicename, type_string);
  if (!(f = fopen(name->str, "r"))) return makebool(FALSE);

  LOCALSTR(fname, nicename);
  read_from_file(f, FALSE);

  pmemory = new_block();
  lexloc.filename = fname;
  if ((mf = parse(pmemory)))
    parsed = mudlle_parse(pmemory, mf);
  else
    parsed = makebool(FALSE);

  free_block(pmemory);
  fclose(f);

  return parsed;
}


TYPEDOP("closure?", closurep, "x -> b. True if x is a closure",
	1, (value x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(POINTERP(x) && OBJTYPE(x) == type_function);
}

TYPEDOP("primitive?", primitivep, "x -> b. True if x is a primitive",
	1, (value x),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "x.n")
{
  return makebool(PRIMITIVEP(x));
}

TYPEDOP("primitive_nargs", primitive_nargs,
"primitive -> b. Returns # of arguments of primitive",
	1, (value p),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "f.n")
{
  if (!PRIMITIVEP(p))
    RUNTIME_ERROR(error_bad_type);

  return makeint(PRIMARGS(p));
}

TYPEDOP("primitive_flags", primitive_flags, 
"primitive -> n. Returns flags of primitive",
	1, (value p),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "f.n")
{
  if (!PRIMITIVEP(p))
    RUNTIME_ERROR(error_bad_type);

  return makeint(PRIMOP(globals, p)->flags);
}

TYPEDOP("primitive_type", primitive_type, 
"primitive -> l. Returns primitive's type signature",
	1, (value p),
	OP_LEAF | OP_NOESCAPE, "f.l")
{
  struct list *l = NULL;
  const char **atyping;

  if (!PRIMITIVEP(p))
    RUNTIME_ERROR(error_bad_type);

  atyping = PRIMOP(globals, p)->type;
  if (atyping)
    {
      GCPRO1(l);
      while (*atyping)
	{
	  struct string *sig = alloc_string(*atyping++);

	  l = alloc_list(sig, l);
	}
      GCPOP(1);
    }
  return l;	
}

UNSAFEOP("make_primitive", make_primitve,
	  "n -> f. Returns nth primitive",
	  1, (value n), OP_LEAF | OP_NOESCAPE)
{
  ISINT(n);
  return PRIMITIVE_NB_TO_ATOM(intval(n));
}

UNSAFEOP("global_table", global_table, "gstate -> table. Returns global symbol table",
	 1, (struct global_state *gstate),
	 OP_LEAF | OP_NOALLOC | OP_NOESCAPE)
{
  is_gstate(gstate);
  return gstate->global;
}

TYPEDOP("global_lookup", global_lookup, 
"gstate s -> n. Returns index of global variable s",
	2, (struct global_state *gstate, struct string *name),
	OP_LEAF | OP_NOESCAPE, "s.n")
{
  is_gstate(gstate);
  TYPEIS(name, type_string);

  return makeint(mglobal_lookup(gstate, name));
}

TYPEDOP("global_add", global_add, 
	"gstate s -> n. Add and return index of global variable s",
	2, (struct global_state *gstate, struct string *name),
	OP_LEAF | OP_NOESCAPE, "s.n")
{
  char *tname;

  TYPEIS(name, type_string);
  LOCALSTR(tname, name);

  return makeint(global_add(gstate, tname, stype_any));
}

TYPEDOP("global_value", global_value, 
"gstate n -> x. Returns value of global variable n",
	2, (struct global_state *gstate, value goffset),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "n.x")
{
  ivalue n;

  is_gstate(gstate);
  ISINT(goffset); n = intval(goffset);
  if (n < 0 || n >= intval(gstate->environment->used)) RUNTIME_ERROR(error_bad_value);

  return GVAR(gstate, n);
}

UNSAFEOP("global_set!", global_setb, 
"gstate n x -> . Sets global variable n to x. Fails if n is readonly",
	 3, (struct global_state *gstate, value goffset, value x),
	 OP_LEAF | OP_NOALLOC)
{
  ivalue n;

  is_gstate(gstate);
  ISINT(goffset); n = intval(goffset);
  if (n < 0 || n >= intval(gstate->environment->used) || GCONSTANT(gstate, n))
    RUNTIME_ERROR(error_bad_value);

  GVAR(gstate, n) = x;
  undefined();
}

TYPEDOP("module_status", module_status, "gstate s -> n. Returns status of module s",
	2, (struct global_state *gstate, struct string *name),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "s.n")
{
  is_gstate(gstate);
  TYPEIS(name, type_string);

  return makeint(module_status(gstate, name->str));
}

UNSAFEOP("module_set!", module_setb, "gstate s n -> . Sets status of module s to n",
	 3, (struct global_state *gstate, struct string *name, value status),
	 OP_LEAF | OP_NOALLOC | OP_NOESCAPE)
{
  char *tname;

  is_gstate(gstate);
  TYPEIS(name, type_string);
  LOCALSTR(tname, name);
  ISINT(status);

  module_set(gstate, tname, intval(status));

  undefined();
}

UNSAFEOP("module_unload", module_unload, 
"gstate s -> b. Unload module s, false if protected",
	 2, (struct global_state *gstate, struct string *name),
	 OP_LEAF | OP_NOALLOC)
{
  is_gstate(gstate);
  TYPEIS(name, type_string);

  return makebool(module_unload(gstate, name->str));
}

#if 0
TYPEDOP("module_require", module_require, 
"gstate s -> n. Load module s if needed, return its new status",
	2, (struct global_state *gstate, struct string *name),
	0, "s.n")
{
  char *tname;

  is_gstate(gstate);
  TYPEIS(name, type_string);
  LOCALSTR(tname, name);

  return makeint(module_require(tname));
}
#endif

TYPEDOP("module_vstatus", module_vstatus, 
"gstate n -> s/n. Return status of global variable n",
	2, (struct global_state *gstate, value goffset),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "n.S")
{
  ivalue n;
  struct string *mod;
  int status;

  is_gstate(gstate);
  ISINT(goffset); n = intval(goffset);
  if (n < 0 || n >= intval(gstate->environment->used)) RUNTIME_ERROR(error_bad_value);

  status = module_vstatus(gstate, n, &mod);
  if (status == var_module) return mod;
  else return makeint(status);
}

UNSAFEOP("module_vset!", module_vsetb, 
"gstate n s/n -> . Sets status of global variable n",
	 3, (struct global_state *gstate, value goffset, value status),
	 OP_LEAF | OP_NOALLOC)
{
  ivalue n;
  struct string *mod;

  is_gstate(gstate);
  ISINT(goffset); n = intval(goffset);
  if (n < 0 || n >= intval(gstate->environment->used)) RUNTIME_ERROR(error_bad_value);

  if (INTEGERP(status))
    {
      if (status != makeint(var_normal) && status != makeint(var_write))
	RUNTIME_ERROR(error_bad_value);

      mod = NULL;
    }
  else
    {
      mod = status;
      TYPEIS(mod, type_string);
      status = makeint(var_module);
    }
  return makebool(module_vset(gstate, n, intval(status), mod));
}

UNSAFEOP("module_table", module_table, 
"gstate -> table. Returns module status table",
	 1, (struct global_state *gstate),
	 OP_LEAF | OP_NOALLOC | OP_NOESCAPE)
{
  is_gstate(gstate);
  return gstate->modules;
}

OPERATION("remote_save", remote_save, 
"rstate x -> s. Dump x to string for remote machine rstate",
	  2, (struct remote_state *rstate, value x),
	  OP_LEAF | OP_NOESCAPE)
{
  uvalue size, rglobals;
  block_t mem = new_block();
  u8 *dumpmem;
  struct string *data, *dglobals;
  struct vector *dump;

  /* Lots more checks... */
  TYPEIS(rstate, type_vector);

  if (!remote_save(mem, rstate, x, &dumpmem, &rglobals, &size))
    {
      free_block(mem);
      return makebool(FALSE);
    }

  dump = alloc_vector(2);

  GCPRO1(dump);
  data = alloc_string_n(rglobals);
  dump->data[0] = data;
  memcpy(data->str, dumpmem, rglobals);

  dglobals = alloc_string_n(size - rglobals);
  dump->data[1] = dglobals;
  memcpy(dglobals->str, dumpmem + rglobals, size - rglobals);
  GCPOP(1);

  free_block(mem);

  return dump;
}

static value alloc_state(struct c_machine_specification *cms)
{
  struct machine_specification *machine =
    (struct machine_specification *)allocate_record(type_vector, 4);
  struct extptr *pms;
  struct global_state *gstate;
  /* Leaky. */
  struct c_machine_specification *copycms = xmalloc(sizeof *copycms);

  *copycms = *cms;

  GCPRO1(machine);
  pms = alloc_extptr(copycms);
  GCPOP(1);
  machine->c_machine_specification = pms;
  gstate = new_global_state(machine);
  GCPRO1(gstate);
  runtime_setup(gstate, 0, NULL);
  GCPOP(1);

  return alloc_remote_state(gstate);
}

UNSAFEOP("new_imate_state", new_imate_state, 
	 " -> rstate. Returns a new global state for int-based mate-motlle",
	 0, (void),
	 OP_LEAF | OP_NOESCAPE)
{
  return alloc_state(&mate_imachine_specification);
}

UNSAFEOP("new_fmate_state", new_fmate_state, 
	 " -> rstate. Returns a new global state for float-based mate-motlle",
	 0, (void),
	 OP_LEAF | OP_NOESCAPE)
{
  return alloc_state(&mate_fmachine_specification);
}

UNSAFEOP("set_gstate_primops!", set_gstate_primops,
	 "gstate v -> . Internal use. Will change.",
	 2, (struct global_state *gstate, struct vector *nargs),
	 OP_LEAF)
{
  /* Leaky. Yucky. */
  struct primitive_ext *prims, **primarray;
  int nprims, i;
  struct c_machine_specification *mspec;

  is_gstate(gstate);
  TYPEIS(nargs, type_vector);
  nprims = vector_len(nargs);
  for (i = 0; i < nprims; i++)
    ISINT(nargs->data[i]);
  mspec = C_MACHINE_SPECIFICATION(gstate->machine);

  primarray = xmalloc(nprims * sizeof *primarray);
  prims = xmalloc(nprims * sizeof *prims);
  for (i = 0; i < nprims; i++)
    {
      primarray[i] = &prims[i];
      prims[i].nargs = intval(nargs->data[i]);
    }

  mspec->primops = primarray;
  mspec->primop_count = nprims;

  undefined();
}

UNSAFEOP("set_gstate_bytecodes!", set_gstate_bytecodes,
	 "gstate s -> . Internal use. Will change.",
	 2, (struct global_state *gstate, struct string *bytecodes),
	 OP_LEAF)
{
  /* Leaky. Yucky. */
  struct c_machine_specification *mspec;

  is_gstate(gstate);
  TYPEIS(bytecodes, type_string);
  if (string_len(bytecodes) != 256)
    RUNTIME_ERROR(error_bad_value);

  mspec = C_MACHINE_SPECIFICATION(gstate->machine);
  mspec->layout.bytecodes = xmalloc(256);
  memcpy(mspec->layout.bytecodes, bytecodes->str, 256);

  undefined();
}

UNSAFEOP("string_compile", string_compile,
"gstate s b -> fn. Compile s for global state context gstate.\n\
If b is true, compile as scheme string.",
	 3, (struct global_state *gstate, struct string *s, value is_scheme), 0)
{
  block_t nb;

  is_gstate(gstate);
  TYPEIS(s, type_string);

  nb = new_block();
  read_from_string(bstrdup(nb, s->str), istrue(is_scheme));
  compile_and_run(nb, gstate, "<remote>", NULL, TRUE);
  return PRIMITIVE_STOLE_CC;
}

UNSAFEOP("file_compile", file_compile,
"gstate s b -> fn. Compile file s for global state context gstate.\n\
If b is true, compile as scheme file.",
	 3, (struct global_state *gstate, struct string *s, value is_scheme), 0)
{
  block_t nb;
  const char *fname;
  FILE *f;

  is_gstate(gstate);
  TYPEIS(s, type_string);

  f = fopen(s->str, "r");
  if (f)
    {
      nb = new_block();
      fname = bstrdup(nb, s->str);
      read_from_file(f, istrue(is_scheme));
      compile_and_run(nb, gstate, fname, NULL, TRUE);
      return PRIMITIVE_STOLE_CC;
    }
  else
    RUNTIME_ERROR(error_bad_value);
}

UNSAFEOP("closure_code", remote_toplevel_closure,
	 "fn -> code. Remove code of a 0-variable closure",
	 1, (struct closure *c), 0)
{
  TYPEIS(c, type_function);

  if (c->o.size != offsetof(struct closure, variables))
    RUNTIME_ERROR(error_bad_value);
  return c->code;
}

#if DEFINE_GLOBALS
GLOBALS(support)
{
  /* Primitive flags */
  system_define("OP_LEAF", makeint(OP_LEAF));
  system_define("OP_NOALLOC", makeint(OP_NOALLOC));
  system_define("OP_CLEAN", makeint(OP_CLEAN));
  system_define("OP_NOESCAPE", makeint(OP_NOESCAPE));

  /* Mudlle object flags */
  system_define("MUDLLE_READONLY", makeint(OBJ_READONLY));
  system_define("MUDLLE_IMMUTABLE", makeint(OBJ_IMMUTABLE));

  /* Module support */
  system_define("module_unloaded", makeint(module_unloaded));
  system_define("module_error", makeint(module_error));
  system_define("module_loading", makeint(module_loading));
  system_define("module_loaded", makeint(module_loaded));
  system_define("module_protected", makeint(module_protected));
  system_define("var_normal", makeint(var_normal));
  system_define("var_write", makeint(var_write));

  /* C options information */
#ifdef GCDEBUG
  system_define("OPTION_GCDEBUG", makebool(TRUE));
#else
  system_define("OPTION_GCDEBUG", makebool(FALSE));
#endif

#define BC(name, value) system_define("bytecode_" #name, makeint(value));
#include "bytecodes.h"
#undef BC
}
#endif
