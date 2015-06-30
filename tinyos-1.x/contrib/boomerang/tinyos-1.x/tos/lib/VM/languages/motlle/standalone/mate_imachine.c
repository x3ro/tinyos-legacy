#include <stddef.h>
#include "mudlle.h"

typedef u16 mate_value;
typedef u16 mate_uvalue; /* The correspondingly-sized unsigned integer type */
typedef i16 mate_ivalue;

#define MATE_ATOM_BASE 0x8000
#define MATE_MAKE_ATOM(n) ((mate_value)(((n) << 1) + MATE_ATOM_BASE))
#define MATE_MAKE_INT(n) ((mate_value)((n) << 1 | 1))
#define MATE_MAKE_PTR(offset) ((mate_value)(offset))

#define mate_machine_specification mate_imachine_specification
#include "mate_machine.inc"
