#include <stddef.h>
#include "mudlle.h"

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

#define mate_machine_specification mate_fmachine_specification
#include "mate_machine.inc"
