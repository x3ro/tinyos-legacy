#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include "mudlle.h"
#include "smotlle.h"

static bool read_dump(char *from)
{
  int fd = open(from, O_RDONLY);
  bool ok = FALSE;
  uvalue size;
  value env;

  if (fd < 0)
    return FALSE;

  if (read(fd, &size, sizeof size) == sizeof size &&
      read(fd, &env, sizeof env) == sizeof env &&
      read(fd, memory, size) == size)
    {
      motlle_init(size, env);
      ok = TRUE;
    }

  close(fd);

  return ok;
}

int main(int argc, char **argv)
{
  if (argc == 1)
    {
      printf("%p\n", memory);
      exit(0);
    }
  if (argc != 2 || !read_dump(argv[1]))
    {
      fprintf(stderr, "Usage: %s <dumpfile>\n", argv[0]);
      exit(2);
    }

  motlle_start();

  for (;;)
    motlle_run1();
}
