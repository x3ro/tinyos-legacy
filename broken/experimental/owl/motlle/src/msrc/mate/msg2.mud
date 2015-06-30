msgs = fn (me, dest)
  if (id() == me)
    {
      any sent = 0, received = 0;

      settimer0(20);
      Timer0 = fn ()
	{
	  sent++;
	  send(dest, encode(vector(id(), sent, received)));
	  led(25);
	};
      Receive = fn ()
	{
	  // start counting sends on 1st receive
	  if (received == 0)
	    sent = 0;
	  led(26);
	  received++;
	};
    };

msgs(0, 16);
msgs(16, 0);
