#include <stdlib.h>
#include "mudlle.h"
#include "memory.h"
#include "error.h"

/* The memory is shared between GC and stack. So we centralise basic
   allocation here. */

u8 thememory[MEMORY_SIZE+1];

void stack_reserve(uvalue n)
/* Effects: make sure n more bytes can be allocated (for the stack or
     for the GC), garbage_collect if not. If after garbage collection
     n bytes are not available, then throw error_no_memory
   Returns: TRUE if n bytes were available, FALSE if an error was thrown
*/
{
#if 0
  if (!CANGC(0, n))
    {
      garbage_collect();
      if (!CANGC(0, n))
	runtime_error(error_no_memory);
    }
#else
  if (sp - n < splimit)
    {
      garbage_collect();
      if (sp - n < splimit)
	runtime_error(error_no_memory);
    }
#endif
}

bool try_gc_reserve(uvalue n)
{
  if (!CANGC(n, 0))
    {
      garbage_collect();
      if (!CANGC(n, 0))
	return FALSE;
    }
  return TRUE;
}

void gc_reserve(uvalue n)
{
  if (!try_gc_reserve(n))
    runtime_error(error_no_memory);
}

u8 *sp, *fp, *splimit;

void stack_push(value x)
{
  sp -= sizeof(value);
  *(value *)sp = x;
}

value stack_pop(void)
{
  u8 *oldsp = sp;

  sp += sizeof(value);
  return *(value *)oldsp;
}

#ifndef TINY
void stack_popn(u8 n)
{
  sp += n * sizeof(value);
}

value stack_get(u8 i)
{
  return ((value *)sp)[i];
}
#endif

void stack_init(void)
{
  sp = fp = memory + MEMORY_SIZE;
}

void *push_frame(framekind action, uvalue size)
{
  u8 *oldfp = fp;
  struct generic_frame *frame;

  stack_reserve(size);
  sp -= size;
  fp = sp;
  frame = (struct generic_frame *)fp;
  frame->action = action;
  frame->oldfp = oldfp;

  return frame;
}

void pop_frame(u8 **ffp, u8 **fsp, uvalue size)
{
  *fsp = *ffp + size;
  *ffp = ((struct generic_frame *)*ffp)->oldfp;
}

static void exec(void *data)
{
  FA_EXECUTE();
}

void motlle_run1(void)
{
  int err = protect(exec, NULL);

  if (err >= 0)
    mthrow(SIGNAL_ERROR, makeint(err));
}

