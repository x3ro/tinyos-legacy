msgs = fn (me, dest)
  if (id() == me)
    {
      settimer0(20);
      Timer0 = fn ()
	{
	  led(25);
	  send(dest, "test");
	};
      Receive = fn ()
        led(26);
    };

msgs(0, 16);
msgs(16, 0);
