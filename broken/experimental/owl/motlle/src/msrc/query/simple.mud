/*
   select nodeid, parent, light, ... sample period N
*/

mhop_set_update(30);

if (id() == 0)
  {
    mhop_set_forwarding(0);
    Intercept = fn () send(126, intercept_msg());
    Snoop = fn () send(126, snoop_msg());
  }
else
  {
    Timer0 = fn ()
      {
	led(25);
	mhopsend(encode(vector(next_epoch(), id(), parent(), light())));
      };

    settimer0(100);

    epoch = 0;
    set_epoch = fn (newepoch) epoch = newepoch;

    next_epoch = fn () set_epoch(epoch + 1);

    snoop_epoch = fn (msg)
      {
	vector v = decode(msg, vector(2));
	if (v[0] > epoch + 1)
	  set_epoch(v[0]);
      };

    Snoop = fn ()
      snoop_epoch(snoop_msg());

    Intercept = fn ()
      {
	string msg = intercept_msg();

	snoop_epoch(msg);	// to advance epoch if necessary
	if (intercept2 != '())
	  intercept2(msg);
      };
  };
