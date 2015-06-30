#include <stddef.h>
#include "mudlle.h"
#include "machine.h"
#include "dump.h"
#include "primitives.h"
#include "mate_machine.h"

#undef MATE_FLOAT
#ifdef MATE_FLOAT
typedef u32 mate_value;
typedef u32 mate_uvalue; /* The correspondingly-sized unsigned integer type */
typedef i16 mate_ivalue;

enum {
  mate_kind_int = 0,
  mate_kind_atom = 1,
  mate_kind_ptr = 2
};
bool mate_isfloat(mate_value x) {
  return (x & 1) && (x >> 23) == 511;
}

float mate_asfloat(mate_value x) {
  return *(float *)&x;
}

u16 mate_as16(mate_value x) {
  return x >> 3;
}

u8 mate_kind16(mate_value x) {
  return (x >> 1) & 3;
}

mate_value mate_make16(uint8_t kind, u16 val) {
  return 511L << 23 | val << 3 | kind << 1 | 1;
}

#define MATE_MAKE_ATOM(n) (mate_make16(mate_kind_atom, (n)))
#define MATE_MAKE_INT(n) (mate_make16(mate_kind_int, (n)))
#define MATE_MAKE_PTR(offset) (mate_make16(mate_kind_ptr, (offset)))

#else
typedef u16 mate_value;
typedef u16 mate_uvalue; /* The correspondingly-sized unsigned integer type */
typedef i16 mate_ivalue;

#define MATE_ATOM_BASE 0x8000
#define MATE_MAKE_ATOM(n) ((mate_value)(((n) << 1) + MATE_ATOM_BASE))
#define MATE_MAKE_INT(n) ((n) << 1 | 1)
#define MATE_MAKE_PTR(offset) (offset)
#endif

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

  if (!obj->forwarded)
    save_copy_and_scan(&mate_machine_specification.layout, obj);

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

#include "runtime/mprimops.c"

struct c_machine_specification mate_machine_specification = {
  mprimops,
  sizeof(mprimops) / sizeof(*mprimops),
  NULL, 0, /* global initialisers */
  { /* layout */
    sizeof(mate_value), MATE_ALIGNMENT, sizeof(mate_header_type) + 2, FALSE,
    mate_forward, mate_write_header, mate_copy_code_header
  }
};
