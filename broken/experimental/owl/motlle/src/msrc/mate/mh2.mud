epoch = 0;

if (id() == 0)
  {
    Intercept = fn () send(126, intercept_msg());
    Snoop = fn () send(126, snoop_msg());
  }
else
  {
    Timer0 = fn ()
      {
	led(25);
	mhopsend(encode(vector(++epoch, id(), parent(), light())));
      };

    settimer0(20);
  };

