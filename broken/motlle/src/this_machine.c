#include <stddef.h>
#include "mudlle.h"
#include "machine.h"
#include "dump.h"

static max_value self_forward(value x);
static max_value self_make_header(max_value type, max_value flags, max_value size);
static void self_copy_code_header(u8 *newobj, struct code *code);


#include "runtime/primops.c"

struct c_machine_specification this_machine_specification = {
  primops,
  sizeof(primops) / sizeof(*primops),
  global_initialisers,
  sizeof(global_initialisers) / sizeof(*global_initialisers),
  { /* layout */
    sizeof(value), ALIGNMENT, offsetof(struct code, ins), FALSE,
    self_forward, self_make_header, self_copy_code_header
  }
};

#define this_layout this_machine_specification.layout

#define primops sprimops
#define global_initialisers sglobal_initialisers
#include "runtime/sprimops.c"
#undef primops
#undef global_initialisers

struct c_machine_specification standalone_machine_specification = {
  sprimops,
  sizeof(sprimops) / sizeof(*sprimops),
  sglobal_initialisers,
  sizeof(sglobal_initialisers) / sizeof(*sglobal_initialisers),
  { /* layout */
    sizeof(value), ALIGNMENT, offsetof(struct code, ins), FALSE,
    self_forward, self_make_header, self_copy_code_header
  }
};

static max_value self_forward(value x)
{
  struct obj *obj;

  if (ATOMP(x) || INTEGERP(x) || !x)
    return (max_value)(uvalue)x;

  obj = x;
  if (obj->forwarded)
    return obj->size;

  save_copy_and_scan(&this_layout, obj);

  return obj->size;
}

static max_value self_make_header(max_value type, max_value flags, max_value size)
{
  struct obj hdr;

  hdr.type = type;
  hdr.forwarded = FALSE;
  SETFLAGS(hdr, flags);
  hdr.size = size;

  assert(sizeof(struct obj) == sizeof(uvalue));

  return *(uvalue *)&hdr;
}

static void self_copy_code_header(u8 *newobj, struct code *code)
{
  struct code *newcode = (struct code *)newobj;

  newcode->nb_locals = code->nb_locals;
  newcode->stkdepth = code->stkdepth;
  newcode->help = (value)(uvalue)self_forward(code->help);
  newcode->filename = (value)(uvalue)self_forward(code->filename);
  newcode->varname = (value)(uvalue)self_forward(code->varname);
  newcode->nargs = code->nargs;
}
