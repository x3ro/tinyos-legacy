#include "machine.h"
#include "dump.h"
#include "primitives.h"
#include "mate_machine.h"
#include "table.h"
#include "global.h"

typedef u16 mate_header_type;
#define MATE_ALIGNMENT sizeof(mate_value)

enum {
  m_itype_code,			// rep: boxed, user: type_function
  m_type_null,		// rep: boxed (internal use) or atom (regular null)
  m_type_string,			// rep: boxed
  m_type_vector,			// rep: boxed
  m_type_pair,			// rep: boxed
  m_itype_closure		// rep: boxed, user: type_function
};

static bool mate_gsymbol(struct symbol *sym, max_value *oval)
{
  struct symbol *gsym;

  if (INTEGERP(sym->data) &&
      table_lookup(remote_gstate->gsymbols, sym->name->str, &gsym) &&
      gsym == sym)
    {
      struct c_machine_specification *cms = 
	remote_gstate->machine->c_machine_specification->external;
      *oval =  MATE_MAKE_ATOM(intval(sym->data) + cms->primop_count + 1);
      return TRUE;
    }
  else
    return FALSE;
}

static max_value mate_forward(value x)
{
  struct obj *obj;

  if (ATOMP(x))
    return MATE_MAKE_ATOM(ATOM_VALUE(x) + 1); // because of null

  if (INTEGERP(x))
    return MATE_MAKE_INT(intval(x)); /* Warning: implicit mod operation */

  if (!x)
    return MATE_MAKE_ATOM(0); // null in the Mate-based VM

  obj = x;
  if (obj->type == type_float)
    return *(u32 *)&((struct mudlle_float *)obj)->d;

  if (obj->type == type_symbol)
    {
      max_value val;

      if (mate_gsymbol((struct symbol *)obj, &val))
	return val;
    }

  if (!obj->forwarded)
    {
      struct c_machine_specification *cms = 
	remote_gstate->machine->c_machine_specification->external;

      save_copy_and_scan(&cms->layout, obj);
    }

  return MATE_MAKE_PTR(obj->size);
}

static void mate_write_header(u8 *to, max_value type, max_value flags, max_value size)
{
  mate_header_type hdr;
  uint8_t mate_type;

  switch (type)
    {
    case itype_code: mate_type = m_itype_code; break;
    case type_function: mate_type = m_itype_closure; break;
    case type_string: mate_type = m_type_string; break;
    case type_vector: mate_type = m_type_vector; break;
    case type_pair: mate_type = m_type_pair; break;
    default: mate_type = m_type_null; break;
    }
  hdr = (size - sizeof(mate_header_type)) << 4 | mate_type << 1;

  to[0] = hdr;
  to[1] = hdr >> 8;
}

static void mate_copy_code_header(u8 *newobj, struct code *code)
{
  newobj[sizeof(mate_header_type) + 0] = code->nb_locals;
  newobj[sizeof(mate_header_type) + 1] = code->nargs;
}

struct c_machine_specification mate_machine_specification = {
  /* primops and constants are set in mudlle */
  NULL, 0, /* primops */
  NULL, 0, /* global initialisers */
  { /* layout */
    sizeof(mate_value), MATE_ALIGNMENT, sizeof(mate_header_type) + 2, FALSE,
    mate_forward, mate_write_header, mate_copy_code_header
  }
};
