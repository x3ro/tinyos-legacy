infinite = fn () {
  any msg;
  msg = "";
  while (1) { msg_send(msg); led!(led_r_toggle); sleep(1); }
};
dump("send", infinite);
