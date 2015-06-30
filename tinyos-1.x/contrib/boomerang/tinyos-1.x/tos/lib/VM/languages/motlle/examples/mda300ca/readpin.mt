setpindirection(2, direction_in);
any n = 0;
for (;;) {
  led(l_blink | l_yellow);
  send(126, encode(vector(++n, readpin(2))));
  sleep(1);
 }
