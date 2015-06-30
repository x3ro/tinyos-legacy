struct foo
{
  unsigned x:12;
  unsigned y:4;
} __attribute__ ((packed));

int main()
{
  printf("%d\n", sizeof(struct foo));
  return 0;
}
