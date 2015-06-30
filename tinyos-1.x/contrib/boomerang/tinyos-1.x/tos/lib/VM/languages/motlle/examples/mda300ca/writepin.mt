setpindirection(2, direction_out);
any n = 0;
for (;;) {
  led(l_blink | l_yellow);
  writepin(2, ++n & 1);
  sleep(1);
 }
