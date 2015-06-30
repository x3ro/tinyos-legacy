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
#include "global.h"
#include <stdlib.h>
#include <string.h>
#ifndef AVR
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <netinet/in.h>
#endif
#include <stddef.h>
#include "alloc.h"
#include "utils.h"
#include "types.h"
#include "runtime/basic.h"
#include "context.h"
#include "interpret.h"

/* Current allocation state */

/* We always allocate forward from the start of the block.  When the block
   is half full, we do a copy to the 2nd half, then move the block back.
   This (will) allow us to use the latter part of the block for the stack. */

u8 *posgc;
static uvalue gc_offset;

/* Roots */
#ifdef AVR
#define MAXGCPRO 8
static value *localpro[MAXGCPRO];
#define init_localpro() (gcpro = localpro)
#else
uvalue localpro_size = 1024; /* Will probably never need increasing... */
value **localpro;
static void init_localpro(void)
{
  gcpro = localpro = xmalloc(localpro_size * sizeof(*localpro));
}

void increase_localpro(void)
{
  value **old_localpro = localpro;

  localpro_size *= 2;
  localpro = xrealloc(localpro, localpro_size * sizeof(*localpro));
  gcpro = localpro + (gcpro - old_localpro);
}
#endif

value **gcpro;			/* C variables which need protection */

#ifndef TINY
struct gcpro_list *gcpro_list;	/* List of values which need protection */
#endif

/* We use the same mechanism to protect local & global vars, we 
   just require all globals to be protected before any localpro are. */
void staticpro(value *pro)
{
  GCPRO1(*pro);
}

static void reset_splimit(void)
{
  splimit = memory + (posgc - memory) * 2;
}

#define INBLOCKN(p, n) \
  assert((u8 *)(p) >= memory && (u8 *)(p) + (n) <= sp)
#define INBLOCK(p) INBLOCKN((p), sizeof(value))

#ifdef GCSTATS
struct gcstats gcstats;
#endif

#ifdef GCQDEBUG
uvalue maxobjsize = 1024; /* biggest object created (ignores stuff done by compiler, but those aren't big) */
#endif

typedef void (*scanop)(value *ptr);

static void scan_cst(u8 *nextinsptr, scanop op)
{
  value v;

  nextinsptr -= sizeof(value);

  /* Note: on no-alignment restriction machines, could do
     forward((value *)nextinsptr); 
  */
  v = RINSCST(nextinsptr);
  op(&v);
  WINSCST(nextinsptr, v);
}

INLINE static u8 *scan(u8 *ptr, scanop op)
{
  struct obj *obj = (struct obj *)ptr;

  ptr += ALIGN(obj->size, ALIGNMENT);

  INBLOCKN(obj, obj->size);
  switch (obj->type)
    {
    default:
      assert(0);
    case type_string: case type_null:
      break;
    case type_function: case type_vector: case type_pair: case itype_variable:
    case type_symbol: case type_table: case type_outputport: {
      struct grecord *rec = (struct grecord *)obj;
      value *o, *recend;

      recend = (value *)((u8 *)rec + rec->o.size);
      o = (value *)rec->data;
      while (o < recend)
	op(o++);
      break;
    }
    case itype_code: {
      struct code *code = (struct code *)obj;
      u8 *scanins, *insend;

#ifndef AVR
      op((value *)&code->help);
      op((value *)&code->filename);
      op((value *)&code->varname);
#endif

      /* Walk through code */
      scanins = code->ins;
      insend = code->ins + code_length(code);
      while (scanins < insend)
	{
	  instruction ins = *scanins;

	  if (ins == op_closure)
	    {
	      scanins += 2 + sizeof(value) + (u8)scanins[1];
	      scan_cst(scanins, op);
	    }
	  else if (ins == op_constant)
	    {
	      scanins += 1 + sizeof(value);
	      scan_cst(scanins, op);
	    }
	  else
	    scanins += ins_size(ins);
	}
    }
    }
  return ptr;
}

void forward(value *ptr)
{
  struct obj *obj = *ptr, *newobj;
  uvalue size, offset;

  if (!POINTERP(obj))
    return;

  size = obj->size;

  if (!obj->forwarded)
    {
      GCCHECK(obj);

#ifdef GCSTATS
      gcstats.nb[obj->type]++;
      gcstats.sizes[obj->type] += size;
#endif

      newobj = (struct obj *)posgc;
      offset = posgc - memory + gc_offset;
      posgc += ALIGN(size, ALIGNMENT);

      INBLOCKN(newobj, size);
      memcpy(newobj, obj, size);
      obj->forwarded = TRUE;
      obj->size = size = offset;
    }
  *ptr = (value)(memory + size);
}

static void forward_roots(void)
/* Forward all roots */
{
  value **scan_localpro;
  u8 *scanfp, *scansp;

#ifndef TINY
  struct gcpro_list *protect_list;
  struct dynpro *dyn;

  /* Forward protected C lists */
  for (protect_list = gcpro_list; protect_list; protect_list = protect_list->next)
    {
      struct local_value *val;

      for (val = protect_list->cl->first; val; val = val->next)
	forward(&val->lvalue);
    }
#endif

  /* Forward protected C vars */
  for (scan_localpro = localpro; scan_localpro < gcpro; scan_localpro++)
    forward(*scan_localpro);
  
  /* Forward the motlle stack */
  scansp = sp; scanfp = fp;
  while (scansp < memory + MEMORY_SIZE)
    FA_GCFORWARD(&scanfp, &scansp);
}

static void do_collection(void)
{
  u8 *data, *old_posgc = posgc;

  gc_offset = memory - posgc;

  forward_roots();

  data = old_posgc;
  while (data < posgc)
    data = scan(data, forward);

  /* Reset & move block */
  assert(posgc <= sp && posgc - old_posgc <= old_posgc - memory);
  memcpy(memory, old_posgc, posgc - old_posgc);
  posgc = memory + (posgc - old_posgc);
  reset_splimit();
}

void garbage_collect(void)
{
#ifndef TINY
  fprintf(stderr, "GC ..."); fflush(stderr);
#endif
  MDBG8(dbg_gc);
  MDBG16(memory);
  MDBG16(posgc);
  MDBG16(sp);
  MDBG16(fp);

#ifdef GCSTATS
  {
    int i;

    gcstats.size = sp;
    gcstats.count++;
    for (i = 0; i < last_type; i++)
      {
	gcstats.lnb[i] = gcstats.anb[i]; gcstats.anb[i] = 0;
	gcstats.lsizes[i] = gcstats.asizes[i]; gcstats.asizes[i] = 0;
	gcstats.nb[i] = gcstats.sizes[i] = 0;
      }
  }
#endif

  do_collection();

  MDBG16(posgc);

#ifdef GCSTATS
  gcstats.usage = posgc - startgc;
#endif

#ifndef TINY
  fprintf(stderr, "\n"); fflush(stderr);
#endif
}

INLINE static value fast_gc_allocate(uvalue n)
/* Requires: n == ALIGN(n, ALIGNMENT)
*/
{
  u8 *newp = posgc;

  assert(CANGC(n, 0));

  posgc += n;

#ifdef GCQDEBUG
  if (n > maxobjsize) maxobjsize = n;
#endif

  return newp;
}

value gc_allocate(uvalue n)
/* Effects: Allocates n bytes and returns a pointer to the start of
     the allocated area.
     DOES ABSOLUTELY NO INITIALISATION. BEWARE!
   Returns: Pointer to allocated area
*/
{
  uvalue aligned = ALIGN(n, ALIGNMENT);
  value v;

  gc_reserve(aligned);
  v = fast_gc_allocate(aligned);
  reset_splimit();
  return v;
}

/* Basic allocation */
/* ---------------- */

struct grecord *unsafe_allocate_record(u8 type, uvalue entries)
{
  uvalue size = sizeof(struct obj) + entries * sizeof(value);
  struct grecord *newp = gc_allocate(size);

  newp->o.size = size;
  newp->o.forwarded = FALSE;
  newp->o.type = type;
  SETFLAGS(newp->o, 0);

  /* WARNING: data is not initialised!!! */
#ifdef GCSTATS
  gcstats.anb[type]++;
  gcstats.asizes[type] += size;
#endif

  return newp;
}

struct grecord *allocate_record(u8 type, uvalue entries)
{
  struct grecord *newp = unsafe_allocate_record(type, entries);
  value *o;

  if (!newp)
    return NULL;

  /* Initialise data to NULL */
  o = (value *)&newp->data;
  while (entries) { entries--; *o++ = NULL; }

  return newp;
}

struct gstring *allocate_string(u8 type, uvalue bytes)
{
  uvalue size = sizeof(struct obj) + bytes;
  struct gstring *newp = gc_allocate(size);

  newp->o.size = size;
  newp->o.forwarded = FALSE;
  newp->o.type = type;
  SETFLAGS(newp->o, OBJ_IMMUTABLE);
#ifdef GCSTATS
  gcstats.anb[type]++;
  gcstats.asizes[type] += size;
#endif

  return newp;
}

void allocate_locals(struct variable **locals, u8 n)
/* Effect: Allocate an array of local variables in an optimised fashion.
*/
{
  gc_reserve(n * ALIGN(sizeof(struct variable), ALIGNMENT));

  while (n--)
    {
      struct variable *v = fast_gc_allocate(ALIGN(sizeof(struct variable), ALIGNMENT));

      v->o.size = sizeof(struct variable);
      v->o.forwarded = FALSE;
      v->o.type = itype_variable;
      SETFLAGS(v->o, 0);

      v->vvalue = *locals;
      *locals++ = v;

#ifdef GCSTATS
      gcstats.anb[itype_variable]++;
      gcstats.asizes[type_vector] += sizeof(struct variable);
#endif
    }
  reset_splimit();
}

#ifdef STANDALONE
/* Relocate GC block to a new address */

static void relocate_value(value *v)
{
  if (POINTERP(*v))
    *(uvalue *)v = (uvalue)*v + gc_offset;
}

static u8 *load_start, *load_end;

static void relocate(void)
{
  u8 *scanp = load_start;

  gc_offset = (uvalue)scanp;
  while (scanp < posgc)
    scanp = scan(scanp, relocate_value);

  reset_splimit();
}

value motlle_data_init(uvalue size)
{
  value start;

  if (!try_gc_reserve(size))
    return NULL;

  load_start = posgc;
  load_end = load_start + size;

  return (value)load_start;
}

value motlle_data(u8 *data, uvalue len)
{
  if (posgc + len > load_end)
    len = load_end - posgc;

  memcpy(posgc, data, len);

  posgc += len;

  if (load_end == posgc)
    {
      relocate();
      return (value)load_start;
    }
  else
    return NULL;
}
#endif

void garbage_init(void)
{
  posgc = memory;
  reset_splimit();
  init_localpro();
}
