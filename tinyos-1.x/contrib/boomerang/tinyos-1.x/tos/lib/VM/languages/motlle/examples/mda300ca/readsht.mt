any n = 0;
for (;;) {
  led(l_blink | l_yellow);
  send(126, encode(vector(++n, temp(),  humidity())));
  sleep(1);
 }
