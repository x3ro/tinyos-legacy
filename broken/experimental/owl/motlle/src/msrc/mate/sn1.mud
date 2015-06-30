if (id())
  settimer0(20);

timer0 = fn ()
  {
    led(26);
    send(0, encode(vector(light(), temp())));
  };

receive = fn ()
  send(126, received_msg());
