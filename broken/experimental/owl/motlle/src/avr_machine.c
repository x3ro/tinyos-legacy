#include <stddef.h>
#include "mudlle.h"
#include "machine.h"
#include "dump.h"
#include "avrlayout.h"

static max_value avr_forward(value x);
static max_value avr_make_header(max_value type, max_value flags, max_value size);
static void avr_copy_code_header(u8 *newobj, struct code *code);


#define primops aprimops
#define global_initialisers aglobal_initialisers
#include "runtime/aprimops.c"
#undef primops
#undef global_initialisers

struct c_machine_specification avr_machine_specification = {
  aprimops,
  sizeof(aprimops) / sizeof(*aprimops),
  aglobal_initialisers,
  sizeof(aglobal_initialisers) / sizeof(*aglobal_initialisers),
  { /* layout */
    sizeof(avr_value), AVR_ALIGNMENT, offsetof(struct avr_code, ins), FALSE,
    avr_forward, avr_make_header, avr_copy_code_header
  }
};

#define avr_layout avr_machine_specification.layout

static max_value avr_forward(value x)
{
  struct obj *obj;

  if (ATOMP(x))
    return AVR_MAKE_ATOM(ATOM_VALUE(x));

  if (INTEGERP(x))
    return (avr_value)x; /* Warning: implicit mod operation */

  if (!x)
    return 0;

  obj = x;
  if (obj->forwarded)
    return obj->size;

  save_copy_and_scan(&avr_layout, obj);

  return obj->size;
}

static max_value avr_make_header(max_value type, max_value flags, max_value size)
{
  struct avr_obj hdr;

  hdr.type = type;
  hdr.forwarded = FALSE;
  AVR_SETFLAGS(hdr, flags);
  hdr.size = size;

  assert(sizeof(struct avr_obj) == sizeof(avr_uvalue));

  return *(avr_uvalue *)&hdr;
}

static void avr_copy_code_header(u8 *newobj, struct code *code)
{
  struct avr_code *newcode = (struct avr_code *)newobj;

  newcode->nb_locals = code->nb_locals;
  newcode->nargs = code->nargs;
}
