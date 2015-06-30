#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include "mudlle.h"
#include "smotlle.h"
#include "smotlle-ipc.h"

int req_s;

static void send_req_load(uvalue size, value env, unsigned char *mem)
{
  req_t req = REQ_LOAD;

  if (write(req_s, &req, sizeof req) == sizeof req &&
      write(req_s, &size, sizeof size) == sizeof size &&
      write(req_s, &env, sizeof env) == sizeof env &&
      write(req_s, mem, size) == size)
    return;
  fprintf(stderr, "request write failed\n");
}

static void run_file(char *from)
{
  int fd = open(from, O_RDONLY);
  bool ok = FALSE;
  uvalue size;
  value env;

  if (fd < 0)
    {
      perror("couldn't open file");
      return;
    }

  if (read(fd, &size, sizeof size) == sizeof size &&
      read(fd, &env, sizeof env) == sizeof env)
    {
      unsigned char *mem = malloc(size);

      if (!mem)
	{
	  fprintf(stderr, "out of memory\n");
	  return;
	}
      if (read(fd, mem, size) == size)
	{
	  send_req_load(size, env, mem);
	  free(mem);
	  return;
	}
      free(mem);
    }
  fprintf(stderr, "invalid dump file %s\n", from);
}

static void pfail(void)
{
  perror("failure");
  exit(2);
}

static void usage(void)
{
  fprintf(stderr, "usage: sreq <commandname> <arguments>...\n\
where the commands are:
  run <filename>: load & run the motlle dump in filename\n");
  exit(2);
}

int main(int argc, char **argv)
{
  struct sockaddr_un addr;
  char *cmd;

  req_s = socket(PF_UNIX, SOCK_STREAM, 0);
  if (req_s == -1)
    pfail();

  addr.sun_family = AF_UNIX;
  strcpy(addr.sun_path, SOCKETNAME);
  if (connect(req_s, (struct sockaddr *)&addr, sizeof addr) == -1)
    pfail();

  if (argc < 2)
    usage();

  cmd = argv[1];

  if (!stricmp(cmd, "run") && argc == 3)
    run_file(argv[2]);
  else
    usage();

  return 0;
}
