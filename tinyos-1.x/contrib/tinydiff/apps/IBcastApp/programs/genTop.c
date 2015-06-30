#include <stdio.h>

int main(int argc, char *argv[])
{

  int i, numNodes, j;

  if (argc != 2)
  {
    printf ("Usage: %s <num-nodes>\n", argv[0]);
    exit(1);
  }

  numNodes = atoi(argv[1]);
  

  for (i = 0, j = 2; i <= (numNodes + 1) / 2 - 2; i++)
  {
    printf("%d:%d %d:%d ", i, 2 * i + 1, i, 2 * i + 2);
    if ((i == j - 2) || (i == (numNodes + 1) / 2 - 2))
    {
      j *= 2;
      printf("\n");
    }
  }

  return 0;
}

