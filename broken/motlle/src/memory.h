#ifndef MEMORY_H
#define MEMORY_H

/* The memory is shared between GC and stack. So we centralise basic
   allocation here. */

extern u8 thememory[];
#define memory ((u8 *)(((uvalue)thememory + 1) & ~1))

void stack_init(void);
void stack_reserve(uvalue n);
void gc_reserve(uvalue n);
bool try_gc_reserve(uvalue n);
/* Effects: make sure n more bytes can be allocated (for the stack or
     for the GC), garbage_collect if not. If after garbage collection
     n bytes are not available, then throw error_no_memory
*/

/* Stack principles:

The stack has a fixed maximum size.

The stack is composed of a number of contiguous stack frames, numbered
from 0 (the oldest frame) to n (the most recent one)

Their are 3 important pointers into a stack frame:
- its start (frame_start)
- its end (frame_end)
- its frame pointer (frame_ptr)

Invariants:
- frame_end(i) == frame_start(i + 1)
- frame_start <= frame_ptr < frame_end
- frame_start(0) == stack && frame_end(n) == sp && frame_ptr(n) == fp

Each frame_ptr points to a framekind function which performs an action
on the current frame pointer:
- fa_execute: continue executing this frame
              only called on frame n
- fa_gcforward: call forward on all GCed values in the frame
- fa_print: print this frame (for stack traces)
- fa_pop: return frame_ptr and frame_end for the previous frame
          (updates *fp and *sp)

To push a frame, the following actions must be performed:
- call stack_reserve(maximum size for this frame)
- compute the new frame_end and frame_ptr and store them in sp and fp
- save the old value of fp somewhere in the new frame
- store the framekind function at fp
- do the frame-specific setup
*/

/* Note: stack grows downwards */

extern u8 *fp, *sp, *splimit;

/* fa_execute is CC, others are not */
enum { fa_execute, fa_gcforward, fa_print, fa_pop, fa_unwind };
typedef u8 frameact;

typedef void (*framekind)(frameact, u8 **ffp, u8 **fsp);

/* Most frames start with this structure, push_frame will allocate and initialise
   it.
*/
struct generic_frame
{
  framekind action;
  u8 *oldfp;
};


void *push_frame(framekind action, uvalue size);
void pop_frame(u8 **ffp, u8 **fsp, uvalue size);

void stack_push(value x);
value stack_pop(void);
void stack_popn(u8 n);
value stack_get(u8 i);

#if 0
#define VALIDATE_ACT(fp) ({ uvalue act = *(uvalue *)(*(fp)); if (act < 0x8000000 || act > 0x8100000) abort(); }), 
#else
#define VALIDATE_ACT(fp)
#endif

#define FRAMEACT(act, fp, sp) (VALIDATE_ACT(fp) (*(framekind *)(*(fp)))((act), (fp), (sp)))
#define FA_EXECUTE() FRAMEACT(fa_execute, &fp, &sp)
#define FA_GCFORWARD(fp, sp) FRAMEACT(fa_gcforward, (fp), (sp))
#define FA_PRINT(fp, sp) FRAMEACT(fa_print, (fp), (sp))
#define FA_POP(fp, sp) FRAMEACT(fa_pop, (fp), (sp))
#define FA_UNWIND(fp, sp) FRAMEACT(fa_unwind, (fp), (sp))

void motlle_run1(void);

#endif
