#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include "mudlle.h"
#include "utils.h"
#include "interpret.h"
#include "global.h"
#include "table.h"
#include "dump.h"

struct remote_state *alloc_remote_state(struct global_state *gstate)
{
  struct remote_state *rs;
  struct vector *globals_used;

  GCPRO1(gstate);
  rs = (struct remote_state *)allocate_record(type_vector, 3);
  rs->gstate = gstate;
  GCPRO1(rs);
  globals_used = alloc_vector(vector_len(gstate->environment->values));
  rs->globals_used = globals_used;
  rs->remote_globals_length = makeint(0);
  GCPOP(2);

  return rs;
}

static u8 *dumpmem;
static u8*dumppos;
static value *globals_used;
static bool new_global;

/* save_forward and save_forward_cst are essentially the
   same as the code in alloc.c. But they are not shared for several reasons:
   - I don't want to extend the code in alloc.c to handle dump because the
     code is not needed on the AVR (minor)
   - The GC may change to a mark&sweep, or mark&compact, but the gc_save
     stuff remains essentially a copy-style operation (major)
   - There will be a data rep change when copying to the AVR (different
     pointer sizes, some fields missing in code objects) (major)
*/

static void save_forward(value *ptr)
{
  struct obj *obj = *ptr, *newobj;
  uvalue size, offset;

  if (!POINTERP(obj))
    return;

  size = obj->size;

  if (!obj->forwarded)
    {
      GCCHECK(obj);

      newobj = (struct obj *)dumppos;
      offset = dumppos - dumpmem;
      dumppos += ALIGN(size, ALIGNMENT);

      memcpy(newobj, obj, size);
      obj->forwarded = TRUE;
      obj->size = size = offset;
    }
  *ptr = (value)size;
}

static void save_forward_cst(u8 *nextinsptr)
{
  value v;

  nextinsptr -= sizeof(value);

  /* Note: on no-alignment restriction machines, could do
     forward((value *)nextinsptr); 
  */
  v = RINSCST(nextinsptr);
  save_forward(&v);
  WINSCST(nextinsptr, v);
}

static u16 insu16(instruction *i)
{
  return i[0] << 8 | i[1];
}

static u8 *save_scan(u8 *ptr)
{
  struct obj *obj = (struct obj *)ptr;

  ptr += ALIGN(obj->size, ALIGNMENT);

  switch (obj->type)
    {
    default:
      assert(0);
    case type_string: case type_null:
      break;
    case type_outputport: case type_table: case type_symbol:
      /* Could also make it fail ? */
      obj->type = type_null;
      break;
    case type_function: case type_vector: case type_pair: {
      struct grecord *rec = (struct grecord *)obj;
      value *o, *recend;

      recend = (value *)((u8 *)rec + rec->o.size);
      o = (value *)rec->data;
      while (o < recend)
	{
	  save_forward(o);
	  o++;
	}
      break;
    }
    case itype_code: {
      struct code *code = (struct code *)obj;
      u8 *scanins, *insend;

      save_forward((value *)&code->help);
      save_forward((value *)&code->filename);
      save_forward((value *)&code->varname);

      /* Walk through code */
      scanins = code->ins;
      insend = code->ins + code_length(code);
      while (scanins < insend)
	{
	  instruction ins = *scanins;

	  if (ins == op_closure)
	    {
	      scanins += 2 + sizeof(value) + (u8)scanins[1];
	      save_forward_cst(scanins);
	    }
	  else if (ins == op_constant)
	    {
	      scanins += 1 + sizeof(value);
	      save_forward_cst(scanins);
	    }
	  else 
	    {
	      switch (ins)
		{
		case op_execute_global1: case op_execute_global2:
		case op_recall + global_var: case op_assign + global_var:
		case op_define: {
		  u16 gvar = insu16(scanins + 1);
		  if (!globals_used[gvar])
		    {
		      new_global = TRUE;
		      globals_used[gvar] = PRIMITIVE_STOLE_CC;
		    }
		  break;
		}
		}
	      scanins += ins_size(ins);
	    }
	}
      break;
    }
    }
  return ptr;
}


static u8 *rewrite_globals(u8 *ptr)
{
  struct obj *obj = (struct obj *)ptr;

  ptr += ALIGN(obj->size, ALIGNMENT);

  switch (obj->type)
    {
    default:
      assert(0);
    case type_string: case type_null:
    case type_outputport: case type_table: case type_symbol:
    case type_function: case type_vector: case type_pair: {
      break;
    }
    case itype_code: {
      struct code *code = (struct code *)obj;
      u8 *scanins, *insend;

      /* Walk through code */
      scanins = code->ins;
      insend = code->ins + code_length(code);
      while (scanins < insend)
	{
	  instruction ins = *scanins;

	  if (ins == op_closure)
	    scanins += 2 + sizeof(value) + (u8)scanins[1];
	  else 
	    {
	      switch (ins)
		{
		case op_execute_global1: case op_execute_global2:
		case op_recall + global_var: case op_assign + global_var:
		case op_define: {
		  u16 gvar = insu16(scanins + 1);

		  assert(INTEGERP(globals_used[gvar]));
		  gvar = intval(globals_used[gvar]);
		  scanins[1] = gvar >> 8;
		  scanins[2] = gvar & 0xff;
		  break;
		}
		}
	      scanins += ins_size(ins);
	    }
	}
      break;
    }
    }
  return ptr;
}


static u8 *restore_size(u8 *ptr, u8 *oldmem)
{
  struct obj *obj = (struct obj *)ptr;
  struct obj *oldobj = (struct obj *)(oldmem + (ptr - memory));

  obj->forwarded = FALSE;
  obj->size = oldobj->size;
  return ptr + ALIGN(obj->size, ALIGNMENT);
}

void remote_save(block_t region, struct remote_state *rstate, value x, 
		 u8 **save_mem, uvalue *globals_offset, uvalue *save_size)
/* Effects: Saves value x, created for global state rstate->gstate,
     to memory area *save_mem (allocated in region) for transmission to
     remote machine with state rstate (updated as a result of remote_save)
   Returns: 
     *save_mem points to the saved memory area
     *save_size is the number of bytes of *save_mem used to save x
     *globals_offset is the offset of the new global variables array (just
     a C-like array from *globals_offset to *save_size)
     (this is the format expected by REQ_LOAD in smain.c)
*/
{
  u8 *scan;
  u8 *oldmem;
  struct env *genv;
  uvalue nglobals, nglobals_used, old_nglobals_used, g;
  uvalue old_gu_length, new_gu_length;
  value *globals_copy;
  value *new_globals;
  struct object_layout *layout =
    &C_MACHINE_SPECIFICATION(rstate->gstate->machine)->layout;

  old_gu_length = vector_len(rstate->globals_used);
  new_gu_length = vector_len(rstate->gstate->environment->values);
  if (old_gu_length != new_gu_length)
    {
      struct vector *new_gu;

      GCPRO2(rstate, x);
      new_gu = alloc_vector(new_gu_length);
      GCPOP(2);
      memcpy(new_gu->data, rstate->globals_used->data,
	     old_gu_length * sizeof(value));
      rstate->globals_used = new_gu;
    }

  oldmem = allocate(region, MEMORY_SIZE);
  memcpy(oldmem, memory, MEMORY_SIZE);

  genv = rstate->gstate->environment;
  old_nglobals_used = nglobals_used = intval(rstate->remote_globals_length);
  nglobals = intval(genv->used);
  globals_copy = allocate(region, sizeof(value) * nglobals);
  memcpy(globals_copy, genv->values->data, sizeof(value) * nglobals);

  *save_mem = dumpmem = allocate(region, MEMORY_SIZE);
  dumppos = dumpmem;
  globals_used = rstate->globals_used->data;

  layout->forward(x);
  scan = dumpmem;

  while (new_global)
    {
      new_global = FALSE;

      /* find the new globals and forward them */
      for (g = 0; g < nglobals; g++)
	if (globals_used[g] == PRIMITIVE_STOLE_CC) /* new */
	  {
	    globals_used[g] = makeint(nglobals_used++);
	    save_forward(&globals_copy[g]);
	  }
    }
  rstate->remote_globals_length = makeint(nglobals_used);

  new_globals = (value *)dumppos;
  dumppos += sizeof(value) * (nglobals_used - old_nglobals_used);
  *globals_offset = (u8 *)new_globals - dumpmem;
      
  for (g = 0; g < nglobals; g++)
    if (globals_used[g])
      {
	ivalue gu = intval(globals_used[g]);

	if (gu >= old_nglobals_used)
	  new_globals[gu - old_nglobals_used] = globals_copy[g];
      }

  scan = dumpmem;
  while (scan < (u8 *)new_globals)
    scan = rewrite_globals(scan);

  /* Restore old memory */
  scan = memory;
  while (scan < posgc)
    scan = restore_size(scan, oldmem);

  *save_size = dumppos - dumpmem;
}

