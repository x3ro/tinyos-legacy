/*
 * Copyright (c) 1993-1999 David Gay and Gustav Hållberg
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software for any
 * purpose, without fee, and without written agreement is hereby granted,
 * provided that the above copyright notice and the following two paragraphs
 * appear in all copies of this software.
 * 
 * IN NO EVENT SHALL DAVID GAY OR GUSTAV HALLBERG BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF DAVID GAY OR
 * GUSTAV HALLBERG HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * DAVID GAY AND GUSTAV HALLBERG SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN
 * "AS IS" BASIS, AND DAVID GAY AND GUSTAV HALLBERG HAVE NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#ifndef ALLOC_H
#define ALLOC_H
#include "mvalues.h"
#include "types.h"

void garbage_init(void);
value motlle_data_init(uvalue size);
value motlle_data(u8 *data, uvalue len);

void garbage_collect(void);
/* Effects: Does a garbage collection
   Modifies: the world
*/
void forward(value *x);

struct grecord *allocate_record(u8 type, uvalue entries);

/* Do not call this function if you don't understand how the gc works !! */
struct grecord *unsafe_allocate_record(u8 type, uvalue entries);

struct gstring *allocate_string(u8 type, uvalue bytes);
void allocate_locals(struct variable **locals, u8 n);
/* Effect: Allocate an array of local variables in an optimised fashion.
*/

value gc_allocate(uvalue n);
/* Effects: Allocates n bytes and returns a pointer to the start of
     the allocated area.
     DOES ABSOLUTELY NO INITIALISATION. BEWARE!
     Do not use if you don't understand the gc ...
   Returns: Pointer to allocated area
*/

#define CANGC(extra_gc, extra_sp) \
  (posgc + (extra_gc) - memory <= (sp - (extra_sp) - (posgc + (extra_gc))))
/* True iff GC can be called after another extra_gc GC bytes and extra_sp stack
   bytes are allocated */

extern u8 *posgc;


#if defined(GCQDEBUG)
extern uvalue maxobjsize;
#define GCCHECK(x)							\
  do if (POINTERP(x) &&							\
	 (((uvalue)(x) & 2) ||						\
	  ((struct obj *)(x))->size > maxobjsize || 			\
	  ((struct obj *)(x))->forwarded ||				\
	  ((struct obj *)(x))->size < 4 ||				\
	  ((struct obj *)(x))->type >= last_type)) \
     assert(0); while (0)
#define GCCHECK_ALLOW_FORWARDED(x)					\
  do if (POINTERP(x) &&							\
	 (((uvalue)(x) & 2) ||						\
	  (((struct obj *)(x))->size > maxobjsize && 			\
	   !((struct obj *)(x))->forwarded) ||	\
	  ((struct obj *)(x))->size < 4 ||				\
	  ((struct obj *)(x))->type >= last_type)) \
     assert(0); while (0)
#else
#define GCCHECK(x) ;
#endif

/* Protection of global variables */
/* ------------------------------ */
void staticpro(value *pro);
/* Requires: no local variables be protected when staticpro is called.
     Note that this is not a big issue as all calls should be in
     early initialisation code.
*/


/* Protection of local variables */
/* ----------------------------- */
extern value **gcpro;

#ifdef AVR
/* There's no recursion in functions calling GCPRO w/ the standalone
   version, so we can reserve the maximum necessary space.
   Currently, this stands at 2 (globals) + maximum needed by a primitive (3)
*/
#define GCPRO_CHECK
#else
extern value **localpro;
extern uvalue localpro_size;
void increase_localpro(void);
#define GCPRO_CHECK ((gcpro - localpro) == localpro_size ? increase_localpro() : 0), 
#endif

#define GCPRO1(var) (GCPRO_CHECK *gcpro++ = (value *)&(var))
#define GCPRO2(var1, var2) (GCPRO1(var1), GCPRO1(var2))
#define GCPOP(n) (gcpro -= (n))


#if 0
/* This is an alternative approach which produces smaller code on the AVR,
   mostly because it doesn't need a frame pointer. But it's not as nice to
   use (values are subsequently accessed w/ an extra level of indirection). */
extern value *gcpro;
#define GCSAVE(var) (*gcpro++ = (var), (void *)(gcpro))
#define GCPOP(n) (gcpro -= (n))
#endif

#ifndef TINY
#include "valuelist.h"

extern struct gcpro_list *gcpro_list; /* List of values which need protection */

struct gcpro_list 
{
    struct gcpro_list *next;
    valuelist *cl;
};

#define PUSH_LIST(var) do { var.next = gcpro_list; \
			    gcpro_list = &var; } while(0)

#define POP_LIST(var) (gcpro_list = var.next)

#define GCPRO_LIST1(var) do { PUSH_LIST(gcpro_list1); \
			      gcpro_list1.cl = &var; } while(0)

#define UNGCPRO_LIST() POP_LIST(gcpro_list1)
#endif

#ifdef GCSTATS
struct gcstats
{
  uvalue size, usage;
  uvalue count;
  uvalue nb[last_type], sizes[last_type];   /* At last GC */
  uvalue lnb[last_type], lsizes[last_type]; /* Amount allocated till GC */
  uvalue anb[last_type], asizes[last_type]; /* Amount allocated since GC */
};

extern struct gcstats gcstats;
#endif

#endif
