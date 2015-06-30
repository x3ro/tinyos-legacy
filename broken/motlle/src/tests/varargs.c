#include <stdarg.h>

short foo[3];

void f(char nargs, ...)
{
  int i;
  va_list args;

  va_start(args, nargs);
  for (i = 0; i < nargs; i++)
    foo[i] = va_arg(args, int);
  va_end(args);
}


short x, y, z;


void g()
{
  f(1, x, y, z);
}

