excite(excite_25v, true);
any n = 0;
for (;;) {
  led(l_blink | l_yellow);
  send(126, encode(vector(++n, adread(4))));
  sleep(1);
 }
