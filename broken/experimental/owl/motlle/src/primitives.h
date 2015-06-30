#ifndef PRIMITIVES_H
#define PRIMITIVES_H

#ifdef __cplusplus
typedef value (*primitive_code)(...);
#else
typedef value (*primitive_code)();
#endif

#ifdef TINY
#define PRIMCALLED(p)
#ifdef AVR
#include <progmem.h>
typedef i8 primargs_type PROGMEM;
typedef primitive_code primfn_type PROGMEM;
#define PRIMARGS(p) ((i8)PRG_RDB(&primargs[ATOM_TO_PRIMITIVE_NB((p))]))
#define PRIMFN(p) ((primitive_code)(PRG_RDB(&primfns[ATOM_TO_PRIMITIVE_NB((p))]) | \
		   PRG_RDB((u8 *)&primfns[ATOM_TO_PRIMITIVE_NB((p))] + 1) << 8))
#else
typedef i8 primargs_type;
typedef primitive_code primfn_type;
#define PRIMARGS(p) (primargs[ATOM_TO_PRIMITIVE_NB((p))])
#define PRIMFN(p) (primfns[ATOM_TO_PRIMITIVE_NB((p))])
#endif

extern primargs_type primargs[];
extern primfn_type primfns[];

#else
#define PRIMFN(p) (PRIMOP(globals, (p))->op)
#define PRIMARGS(p) (PRIMOP(globals, (p))->nargs)
#define PRIMCALLED(p) (PRIMOP(globals, (p))->call_count++)

typedef const char *typing[];

struct primitive_ext		/* The external structure */
{
  const char *name;
  const char *help;
  primitive_code op;
  i16 nargs;
  u16 flags;			/* Helps compiler select calling sequence */
  const char **type;		/* Pointer to a typing array */
  u32 call_count;
};
#endif

#define OP_LEAF 1		/* Operation is leaf (calls no other mudlle code) */
#define OP_NOALLOC 2		/* Operation does not allocate anything */
#define OP_CLEAN 4		/* Operation can be called directly
				   (guarantees GC integrity w/ respect to registers) */
#define OP_NOESCAPE 8		/* Operation does not lead to any variables being
				   changed (~= calls no other mudlle functions) */

#endif
