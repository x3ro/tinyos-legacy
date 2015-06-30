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
#include "module.h"

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
static value *remote_globals_used, *remote_env;
static max_value *new_remote_globals;
static uvalue remote_globals_length;
static struct global_state *remote_gstate;
static bool remote_error;

static void remote_error_msg(const char *format, ...)
{
  va_list args;

  remote_error = TRUE;
  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
}

static u16 insu16(instruction *i)
{
  return i[0] << 8 | i[1];
}

static void wins16(instruction *i, u16 val)
{
  i[0] = val >> 8;
  i[1] = val & 0xff;
}

static max_value converted_code_length(struct object_layout *layout,
				       instruction *start, instruction *end,
				       uvalue *offsetMap)
{
  max_value remote_len = 0;
  instruction *iptr = start;

  while (iptr < end)
    {
      instruction ins = *iptr;

      offsetMap[iptr - start] = remote_len;

      if (ins == OPmclosure)
	{
	  if (iptr[1] == 0) // opt for 0-var closures
	    remote_len += 1 + layout->word_size;
	  else
	    remote_len += 2 + layout->word_size + (u8)iptr[1];
	  iptr += 2 + sizeof(value) + (u8)iptr[1];
	}
      else if (ins == OPmcst)
	{
	  iptr += 1 + sizeof(value);
	  remote_len += 1 + layout->word_size;
	}
      else 
	{
	  uvalue isize = ins_size(ins);

	  remote_len += isize;
	  if (ins == OPmreadg)
	    {
	      struct string *name;
	      u16 gvar = insu16(iptr + 1);
	      
	      if (module_vstatus(remote_gstate, gvar, &name) == var_module)
		// will be replacing by constant
		remote_len += 1 + layout->word_size - isize;
	      else
		remote_len--; /* only 8-bit offset */
	    }
	  else if (ins == OPmwriteg || ins == OPmwritedg ||
		   (ins >= OPmexecg4 && ins <= OPmexecg4 + 15))
	    remote_len--; /* only 8-bit offset */
	  iptr += isize;
	}
    }
  return remote_len;
}

static void remote_write(struct object_layout *layout, u8 *to, max_value val)
{
  size_t nbytes = layout->word_size;

  if (layout->big_endian)
    {
      to += nbytes;
      do
	{
	  *--to = val & 0xff;
	  val >>= 8;
	}
      while (--nbytes > 0);
    }
  else
    do
      {
	*to++ = val & 0xff;
	val >>= 8;
      }
    while (--nbytes > 0);
  assert(val == 0);
}

static void forward_cst(struct object_layout *layout, u8 *to, u8 *from)
{
  from -= sizeof(value);
  to -= layout->word_size;

  remote_write(layout, to, layout->forward(RINSCST(from)));
}

static ivalue read_offset(instruction *ins, uint8_t encoding)
{
  if (encoding == 0)
    return (int8_t)ins[1];
  else if (encoding == 7)
    return (int16_t)insu16(ins + 1);
  else
    return encoding;
}

static void write_offset(instruction *ins, uint8_t encoding, ivalue new)
{
  if (encoding == 0)
    {
      if (!(new >= INTEGER1_MIN && new <= INTEGER1_MAX))
	remote_error_msg("invalid offset 1\n");
      ins[1] = new;
    }
  else if (encoding == 7)
    wins16(ins + 1, new);
  else
    {
      if (!(new >= 1 && new <= 6))
	remote_error_msg("invalid offset 2\n");
      ins[0] += new - encoding;
    }
}

void save_copy_and_scan(struct object_layout *layout, struct obj *obj)
{
  max_value remote_header, remote_size;
  u8 *newobj, *newbody;
  uvalue objsize = obj->size, len;
  const size_t header_size = layout->word_size;

  newobj = dumppos;
  newbody = newobj + header_size;
			
  obj->forwarded = TRUE;
  obj->size = newobj - dumpmem;

  switch (obj->type)
    {
    default:
      assert(0);

    case type_string: {
      len = objsize - offsetof(struct gstring, data) - 1;
      remote_size = header_size + len;
      dumppos += ALIGN(remote_size, layout->alignment);
      memcpy(newbody, ((struct gstring *)obj)->data, len);
      break;
    }
    case type_null: {
      len = objsize - offsetof(struct gstring, data);
      remote_size = header_size + len;
      dumppos += ALIGN(remote_size, layout->alignment);
      memcpy(newbody, ((struct gstring *)obj)->data, len);
      break;
    }
    case type_function: case type_vector: case type_pair: case itype_variable:
    case type_symbol: case type_table: case type_outputport: {
      struct grecord *rec = (struct grecord *)obj;
      uvalue i;

      len = (objsize - offsetof(struct grecord, data)) / sizeof(value);
      remote_size = header_size + len * layout->word_size;
      dumppos += ALIGN(remote_size, layout->alignment);

      for (i = 0; i < len; i++)
	remote_write(layout, newbody + i * layout->word_size,
		     layout->forward(rec->data[i]));
      break;
    }
    case itype_code: {
      struct code *code = (struct code *)obj;
      instruction *scanins, *insend, *insstart, *destins, *deststart;
      ivalue *offsetMap;
      uvalue code_size;

      code_size = objsize - offsetof(struct code, ins);
      offsetMap = alloca(sizeof(uvalue) * code_size);
      scanins = insstart = code->ins;
      insend = code->ins + code_size;
      
      len = converted_code_length(layout, scanins, insend, offsetMap);
      destins = deststart = newobj + layout->code_header_length;
      remote_size = (u8 *)&destins[len] - newobj;
      dumppos += ALIGN(remote_size, layout->alignment);

      layout->copy_code_header(newobj, (struct code *)obj);

      /* Walk through, copy and convert code */
      while (scanins < insend)
	{
	  instruction ins = *scanins;

	  if (ins == OPmclosure)
	    {
	      u8 nvars = (u8)scanins[1];

	      /* Closures with no variables can just be replaced by their code */
	      if (nvars == 0)
		{
		  destins[0] = OPmcst;
		  destins += 1 + layout->word_size;
		}
	      else
		{
		  memcpy(destins, scanins, 2 + nvars);
		  destins += 2 + layout->word_size + nvars;
		}
	      scanins += 2 + sizeof(value) + nvars;
	      forward_cst(layout, destins, scanins);
	    }
	  else if (ins == OPmcst)
	    {
	      *destins = OPmcst;
	      scanins += 1 + sizeof(value);
	      destins += 1 + layout->word_size;
	      forward_cst(layout, destins, scanins);
	    }
	  else if (ins == OPmreadg || ins == OPmwriteg || ins == OPmwritedg ||
		   (ins >= OPmexecg4 && ins <= OPmexecg4 + 15))
	    {
	      uvalue isize, nb;
	      u16 gvar = insu16(scanins + 1);

	      isize = ins_size(ins);
	      destins[0] = scanins[0];

	      if (ins == OPmreadg)
		{
		  struct string *name;

		  if (module_vstatus(remote_gstate, gvar, &name) == var_module)
		    {
		      max_value val = layout->forward(remote_env[gvar]);

		      destins[0] = OPmcst;
		      remote_write(layout, destins + 1, val);
		      destins += 1 + layout->word_size;
		      scanins += isize;
		      continue; /* avoid the increments below */
		    }
		}

	      if (!remote_globals_used[gvar])
		{
		  remote_globals_used[gvar] = makeint(remote_globals_length);
		  new_remote_globals[remote_globals_length] =
		    layout->forward(remote_env[gvar]);
		  remote_globals_length++;
		}
	      nb = intval(remote_globals_used[gvar]);
	      if (nb >= 256)
		remote_error_msg("too many globals (more than 256)");
	      destins[1] = nb;
	      destins += isize - 1;
	      scanins += isize;
	    }
	  else 
	    {
	      uvalue isize;
	      uint8_t encoding;

	      isize = ins_size(ins);
	      memcpy(destins, scanins, isize);
	      switch (ins) /* remap branch offsets */
		{
		case OPmba3 ... OPmba3 + 7:
		  encoding = ins - OPmba3;
		  goto branch;
		case OPmbt3 ... OPmbt3 + 7:
		  encoding = ins - OPmbt3;
		  goto branch;
		case OPmbf3 ... OPmbf3 + 7:
		  encoding = ins - OPmbf3;
		  
		  branch: {
		    ivalue offset = read_offset(scanins, encoding);
		    uvalue dest = (scanins + isize - insstart) + offset;
		    uvalue newdest = offsetMap[dest];
		    ivalue newoffset = newdest - (destins + isize - deststart);

		    /* Only works if code becomes smaller. Oops. */
		    write_offset(destins, encoding, newoffset);
		    break;
		  }
		}
	      destins += isize;
	      scanins += isize;
	    }
	}
      break;
    }
    }
  
  layout->write_header(newobj, obj->type, FLAGS(obj), remote_size);
}

static u8 *restore_size(u8 *ptr, u8 *oldmem)
{
  struct obj *obj = (struct obj *)ptr;
  struct obj *oldobj = (struct obj *)(oldmem + (ptr - memory));

  obj->forwarded = FALSE;
  obj->size = oldobj->size;
  return ptr + ALIGN(obj->size, ALIGNMENT);
}

static void extend_globals_used(struct remote_state *rstate)
{
  uvalue old_gu_length, new_gu_length;

  old_gu_length = vector_len(rstate->globals_used);
  new_gu_length = vector_len(rstate->gstate->environment->values);
  if (old_gu_length != new_gu_length)
    {
      struct vector *new_gu;

      GCPRO1(rstate);
      new_gu = alloc_vector(new_gu_length);
      GCPOP(1);
      memcpy(new_gu->data, rstate->globals_used->data,
	     old_gu_length * sizeof(value));
      rstate->globals_used = new_gu;
    }
}

bool remote_save(block_t region, struct remote_state *rstate, value x, 
		 u8 **save_mem, uvalue *globals_offset, uvalue *save_size)
/* Effects: Saves value x, created for global state rstate->gstate,
     to memory area *save_mem (allocated in region) for transmission to
     remote machine with state rstate (updated as a result of remote_save)
   Returns: TRUE if successful, FALSE for error
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
  uvalue nglobals, old_rgl, g;
  u8 *new_globals;
  struct object_layout *layout =
    &C_MACHINE_SPECIFICATION(rstate->gstate->machine)->layout;

  GCPRO2(rstate, x);
  extend_globals_used(rstate);
  GCPOP(2);

  oldmem = allocate(region, MEMORY_SIZE);
  memcpy(oldmem, memory, MEMORY_SIZE);

  old_rgl = remote_globals_length = intval(rstate->remote_globals_length);
  remote_globals_used = rstate->globals_used->data;

  remote_error = FALSE;
  remote_gstate = rstate->gstate;
  remote_env = rstate->gstate->environment->values->data;
  nglobals = intval(rstate->gstate->environment->used);
  new_remote_globals = allocate(region, sizeof(max_value) * nglobals);

  *save_mem = dumpmem = allocate(region, MEMORY_SIZE);
  dumppos = dumpmem;
  layout->forward(x);

  rstate->remote_globals_length = makeint(remote_globals_length);

  /* Copy the newly found globals to the end of the memory area */
  new_globals = dumppos;
  dumppos += layout->word_size * (remote_globals_length - old_rgl);
  *globals_offset = (u8 *)new_globals - dumpmem;
  for (g = old_rgl; g < remote_globals_length; g++)
    remote_write(layout, new_globals + layout->word_size * (g - old_rgl),
		 new_remote_globals[g]);

  *save_size = dumppos - dumpmem;

  /* Restore old memory */
  scan = memory;
  while (scan < posgc)
    scan = restore_size(scan, oldmem);

  return !remote_error;
}
