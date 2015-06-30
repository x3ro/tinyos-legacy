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

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <signal.h>
#include "mudlle.h"
#include "print.h"
#include "mudlle.h"
#include "call.h"
#include "interpret.h"
#include "runtime/runtime.h"
#include "alloc.h"
#include "utils.h"
#include "mparser.h"
#include "lexer.h"
#include "compile.h"
#include "mvalues.h"
#include "global.h"
#include "module.h"
#include "mcompile.h"
#include "dump.h"
#include "this_machine.h"

#ifdef HAVE_READLINE
#  include <readline/history.h>
#  include <readline/readline.h>
#endif

struct global_state *globals;

struct repl_frame
{
  struct generic_frame g;
  enum { read_line, print_result } state;
  char *line;
};

static void repl_action(frameact action, u8 **ffp, u8 **fsp)
{
  struct repl_frame *frame = (struct repl_frame *)*ffp;

  switch (action)
    {
    case fa_unwind:
      throw_handled();
      frame->state = read_line;
      return;
    case fa_execute:
      switch (frame->state)
	{
	case read_line:
#ifdef HAVE_READLINE
	  if (frame->line)
	    free(frame->line);

	  frame->line = readline((char *)"motlle> ");

	  if (!frame->line)
	    exit(0);

	  if (*frame->line)
	    add_history(frame->line);
#else
	  {
	    char _line[512];

	    frame->line = _line;
	    fputs("mudlle> ", stdout);
	    fflush(stdout); fflush(stderr);
	    if (!fgets(_line, sizeof _line, stdin))
	      exit(0);
	  }
#endif
	  read_from_string(frame->line, FALSE);
	  frame->state = print_result;
	  context.display_error = TRUE;
	  context._mudout = mstdout; context._muderr = mstderr;
	  context.call_count = MAX_CALLS;
	  compile_and_run(NULL, globals, "<interactive>", NULL, FALSE);
	  break;
	case print_result:
	  {
	    value result = stack_pop();

	    printf("Result: ");
	    mprint(mstdout, prt_print, result);
	    printf("\n");
	    frame->state = read_line;
	    break;
	  }
	default:
	  abort();
	}
      break;
    case fa_print:
      mputs("<repl>" EOL, muderr);
      break;
    case fa_gcforward:
      /* fall through */
    case fa_pop:
      pop_frame(ffp, fsp, sizeof(struct repl_frame));
      break;
    default: abort();
    }
}

void push_repl(void)
{
  struct repl_frame *frame = push_frame(repl_action, sizeof(struct repl_frame));

  frame->state = read_line;
#ifdef HAVE_READLINE
  frame->line = NULL;
  rl_bind_key('\t', rl_insert);
#endif
}

static void mload_action(frameact action, u8 **ffp, u8 **fsp)
{
  int exitcode = 0;
  switch (action)
    {
    case fa_unwind: /* program got an error */
      exitcode = 1;
      /* fall through */
    case fa_execute: /* program terminated successfully */
      mflush(mudout); mflush(muderr);
      exit(exitcode); 
    case fa_print: break;
    case fa_gcforward: case fa_pop:
      pop_frame(ffp, fsp, sizeof(struct generic_frame));
      break;
    default: abort();
    }
}

static void mload(void *vfname)
{
  const char *fname = vfname;
  FILE *f;

  context.display_error = TRUE;
  context._mudout = mstdout; context._muderr = mstderr;
  context.call_count = MAX_CALLS;

  if (!(f = fopen(fname, "r")))
    {
      fprintf(stderr, "couldn't find %s\n", fname);
      exit(2);
    }
  push_frame(mload_action, sizeof(struct generic_frame));
  read_from_file(f, FALSE);
  compile_and_run(NULL, globals, fname, NULL, FALSE);
}

static void make_global_state(int argc, char **argv)
{
  struct machine_specification *this_machine =
    (struct machine_specification *)allocate_record(type_vector, 4);
  struct extptr *tms;

  GCPRO1(this_machine);
  tms = alloc_extptr(&this_machine_specification);
  GCPOP(1);
  this_machine->c_machine_specification = tms;
  globals = new_global_state(this_machine);
  staticpro((value *)&globals);
  runtime_setup(globals, argc, argv);
}

static void silly_sig(int s)
{
}

int main(int argc, char **argv)
{
  for (;;)
    switch (getopt(argc, argv, "+d"))
      {
      case 'd':
	debug_lvl++;
	break;
      case '?':
	break;
      case -1:
	goto done;
      }
 done:

  signal(SIGALRM, silly_sig);

  garbage_init();
  interpret_init();
  stack_init();
  runtime_init();
  call_init();
  parser_init();
  compile_init();
  mcompile_init();
  context_init();
  ports_init();
  if (optind < argc)
    make_global_state(argc - optind, argv + optind);
  else
    make_global_state(0, NULL);
  mudio_init();
  print_init();

  if (optind < argc)
    {
      if (protect(mload, argv[optind]) >= 0)
	exit(2); /* compile failed */
    }
  else
    push_repl();

  for (;;)
    motlle_run1();
}
