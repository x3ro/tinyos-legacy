#include <string.h>
#include <stdlib.h>
#include "mudlle.h"
#include "call.h"
#ifndef TINY
#include "ports.h"
#include "print.h"
#include "runtime/runtime.h"
#endif

struct vector *env_values;

#ifndef TINY
#include "runtime/sprimops.c"
#endif

struct standalone_frame
{
  framekind action;
};

static void standalone_action(frameact action, u8 **ffp, u8 **fsp)
{
  switch (action)
    {
    case fa_unwind:
      throw_handled();
      motlle_req_exit(2);
      break;
    case fa_execute:
      motlle_req_exit(0);
      break;
    case fa_print:
#ifndef TINY
      mputs("<standalone>" EOL, muderr);
#endif
      break;
    case fa_gcforward:
      /* fall through */
    case fa_pop:
      /* This frame is special (only present at the top of the stack) */
      *fsp = *ffp = memory + MEMORY_SIZE;
#if 0
      *fsp = *ffp + sizeof(struct standalone_frame);
      *ffp = frame->oldfp;
#endif
      break;
    default: abort();
    }
}

static void push_standalone(void)
{
  struct standalone_frame *frame;

  stack_reserve(sizeof(struct standalone_frame));
  sp -= sizeof(struct standalone_frame);
  fp = sp;
  frame = (struct standalone_frame *)fp;
  frame->action = standalone_action;
}

void motlle_init(void)
{
  garbage_init();
  stack_init();
  env_values = NULL;
  staticpro((value *)&env_values);
  context_init();

#ifndef TINY
  call_init();
  ports_init();
  print_init();
  {
    struct oport *out = make_file_outputport(stdout);

    context._mudout = context._muderr = out;
    context.display_error = TRUE;
  }
#endif
}

uvalue motlle_globals_reserve(uvalue extra_globals)
{
  uvalue oldsize = env_values ? vector_len(env_values) : 0;
  uvalue newsize = oldsize + extra_globals;
  struct vector *new_globals;

  if (!try_gc_reserve(sizeof(struct obj) + newsize * sizeof(value)))
    return 0;
  new_globals = (struct vector *)unsafe_allocate_record(type_vector, newsize);

  if (env_values)
    memcpy(new_globals->data, env_values->data, oldsize * sizeof(value));
  memset(new_globals->data + oldsize, 0, extra_globals * sizeof(value));
  env_values = new_globals;

  return newsize;
}

void motlle_global_set(uvalue n, value v)
{
  env_values->data[n] = v;
}

void motlle_exec(value entry)
{
  stack_init();
  push_standalone();
  setup_call_stack(entry, 0);
}
