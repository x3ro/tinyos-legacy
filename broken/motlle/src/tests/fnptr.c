int f();

int (*ff)();

void g()
{
  ff = f;
}


int h() {
  return ff(0);
}
