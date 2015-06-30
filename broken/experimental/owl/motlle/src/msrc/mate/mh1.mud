epoch = 0;

if (id() == 0)
  Intercept = fn () send(126, intercept_msg())
else
  {
    Timer0 = fn ()
      {
	led(25);
	mhopsend(encode(vector(++epoch, id(), parent())));
      };

    settimer0(20);
  };

