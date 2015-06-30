#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include "mudlle.h"
#include "smotlle-ipc.h"
#include "utils.h"

static bool exit_req;

void motlle_req_leds(u8 cmd)
{
  fprintf(stderr, "leds %d\n", cmd);
}

void motlle_req_exit(u8 exitcode)
{
  exit_req = TRUE;
}

void motlle_req_dbg(u8 x)
{
}

void motlle_req_sleep(ivalue n)
{
  sleep(n);
}

void motlle_req_receive(value newreceiver)
{
}

u8 motlle_req_send_msg(u8 *data, u8 len)
{
  return 0;
}

void motlle_req_msg_data(u8 *data)
{
}

static value read_dump(int fd)
{
  uvalue size;
  uvalue env;

  if (read(fd, &size, sizeof size) == sizeof size &&
      read(fd, &env, sizeof env) == sizeof env)
    {
      u8 *mem = xmalloc(size);

      if (read(fd, mem, size) == size)
	{
	  /* globals are a C-array at the end of the memory area */
	  value *globals = (value *)(mem + env);
	  uvalue nglobals = (size - env) / sizeof(value), i;
	  value start;

	  start = motlle_data_init(env);
	  motlle_data(mem, env);

	  if (nglobals > 0) /* set globals */
	    {
	      uvalue newsize = motlle_globals_reserve(nglobals);

	      if (!newsize) /* out of mem */
		{
		  free(mem);
		  return FALSE;
		}
	      for (i = 0; i < nglobals; i++)
		{
		  value gv = globals[i];

		  if (POINTERP(gv))
		    gv = (u8 *)start + (uvalue)gv;
		  motlle_global_set(i + (newsize - nglobals), gv);
		}
	    }

	  free(mem);

	  return start;
	}
    }
  return FALSE;
}

static void run(value entry)
{
  motlle_exec(entry);

  exit_req = FALSE;
  while (!exit_req)
    motlle_run1();
  fflush(stdout);
}

static void handle_req(int req_s)
{
  req_t req;

  if (read(req_s, &req, sizeof req) == sizeof req)
    {
      switch (req)
	{
	case REQ_LOAD: {
	  value code;

	  if ((code = read_dump(req_s)))
	    {
	      run(code);
	      return;
	    }
	  break;
	}
	case REQ_RESET:
	  motlle_init();
	  return;
	}
    }
  fprintf(stderr, "unknown request\n");
}

static void pfail(void)
{
  perror("failure");
  exit(2);
}

int main(int argc, char **argv)
{
  int accept_s, req_s;
  struct sockaddr_un addr;
  struct sockaddr req_addr;
  socklen_t foo;

  motlle_init();

  accept_s = socket(PF_UNIX, SOCK_STREAM, 0);
  if (accept_s == -1)
    pfail();

  addr.sun_family = AF_UNIX;
  unlink(SOCKETNAME);
  strcpy(addr.sun_path, SOCKETNAME);
  if (bind(accept_s, (struct sockaddr *)&addr, sizeof addr) == -1)
    pfail();

  if (listen(accept_s, 2) == -1)
    pfail();

  for (;;)
    {
      foo = sizeof req_addr;
      req_s = accept(accept_s, &req_addr, &foo);
      if (req_s == -1)
	perror("accepting");
      else
	{
	  handle_req(req_s);
	  close(req_s);
	}
    }
}
