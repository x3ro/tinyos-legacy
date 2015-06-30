/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Value representations

We distinguish two basic formats for values:
  value: Most general value representation, used for parameters
    and local variables in C code
  svalue (stored value): Representation of a value in RAM, on the
    network etc, ie, where (small) size matters
    The svalue type may not be efficiently passable in C code, so
    should be accessed only via the MotlleValues.read and MotlleValues.write
    commands

There are four kinds of values:
  boxed values: An (encoded) pointer to some allocated object which 
    contains the actual value. Type and size information may be stored
    partly in the value and partly in the object
    The pvalue type represents a value that is known to be boxed, but is
    not directly usable (must be converted to one of the boxed vXXX types
    before use).
  integers: A signed integer (some number of bits available).
    The ivalue type represents a value that is known to be an integer.
    The ivalue type is a signed integer type that can be directly used
    (but might have higher precision than integers stored in the value type).
  floats: A floating point number (currently 32 bit IEEE)
    This type is optional, and may not be present in some configurations
    (its presence implies that the basic storage unit is 32 bits)
  atoms: An unsigned integer representing some finite set of entities
    (e.g., primitive functions).
    The avalue type represents a value that is known to be an atom.
    The avalue type is an unsigned integer.

The msize type can represent the size of any motlle object.
*/

/* Disable asserts */
#define NDEBUG

#include "BaseTypes.h"

typedef uint8_t framekind;

/* There's three kinds of types:
   - user-visible types (type_xxx)
   - the internal types
     these may not be in a 1-1 correspondence w/ user-visible types
     (e.g., code vs primitive vs closure)
     we use itype_xxx for the types which are not explicitly user-visible
   - synthetic user-visible types (e.g., list)

   Additionally, only some of these types will show up in boxed objects,
   these are placed first in this list to give them small consecutive numbers
*/

enum {
  itype_code,			// rep: boxed, user: type_function
  type_null,		// rep: boxed (internal use) or atom (regular null)
  type_string,			// rep: boxed
  type_vector,			// rep: boxed
  type_pair,			// rep: boxed
  itype_closure,		// rep: boxed, user: type_function

  // not in boxed objects
  type_int,			// rep: integer
  type_real,			// rep: float
  type_function,		// norep
  itype_primitive,		// rep: atom, user: type_function
  type_symbol,			// rep: atom

  // synthetic types
  stype_none,			// type: {}
  stype_any,			// type: all-types
  stype_list			// type: { pair, null }
};
typedef uint8_t mtype;

// If a type above has a single rep, it has an associated vXXX typedef
typedef ivalue vint;
typedef avalue vprimitive;
typedef avalue vsymbol;

typedef uint8_t instruction;
typedef struct scode
{
  uint8_t nb_locals;
  int8_t nargs;			/* -1 for varargs */
  instruction ins[0];
} *vcode;

typedef struct sstring
{
  unsigned char str[0];		/* Must be null terminated */
} *vstring;

typedef struct svector
{
  svalue data[0];
} *vvector;

typedef struct spair
{
  svalue car, cdr;
} *vpair;

typedef struct sclosure
{
  svalue code;			// May be itype_code, itype_primitive
  svalue variables[0];
} *vclosure;

// motlle errors
enum {
  MOTLLE_ERROR_BAD_FUNCTION = unique("MateError"),
  MOTLLE_ERROR_BAD_TYPE = unique("MateError"),
  MOTLLE_ERROR_DIVIDE_BY_ZERO = unique("MateError"),
  MOTLLE_ERROR_BAD_INDEX = unique("MateError"),
  MOTLLE_ERROR_BAD_VALUE = unique("MateError"),
  MOTLLE_ERROR_VARIABLE_READ_ONLY = unique("MateError"),
  MOTLLE_ERROR_LOOP = unique("MateError"),
  MOTLLE_ERROR_WRONG_PARAMETERS = unique("MateError"),
  MOTLLE_ERROR_VALUE_READ_ONLY = unique("MateError"),
  MOTLLE_ERROR_NO_MATCH = unique("MateError"),
  MOTLLE_ERROR_NO_MEMORY = unique("MateError")
};

enum {
  MOTLLE_INTERPRET_FRAME = unique("MotlleFrame"),
  MOTLLE_MAP_FRAME = unique("MotlleFrame"),
  MOTLLE_FOREACH_FRAME = unique("MotlleFrame"),
  MOTLLE_GCPRO_SIZE = 8
};

#define GCPRO1(var)				\
  call GC.gcpush((var));

#define GCPOP1(var)				\
  ((var) = call GC.gcpopfetch())

#define GCPRO2(var1, var2) \
  call GC.gcpush((var1));  \
  call GC.gcpush((var2));

#define GCPOP2(var1, var2)			\
  ((var2) = call GC.gcpopfetch(),		\
   (var1) = call GC.gcpopfetch())

#define ALIGN_DOWN(n, m) ((n) & ~((m) - 1))
#define ALIGN(n, m) ALIGN_DOWN(((n) + (m) - 1), (m))

enum {
  AM_MOTLLEMSG = 42,
  AM_MOTLLE_MHOPMSG = 43
};

enum {
  GLOBAL_MOTLLE_LOCK = unique("MateLock")
};

#include "MotllePlatform.h"
