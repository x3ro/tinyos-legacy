watchpin(1);
any n = 0;
any pin()
{
  led(l_blink | l_yellow);
  send(126, encode(vector(++n, readpin(2))));
}
