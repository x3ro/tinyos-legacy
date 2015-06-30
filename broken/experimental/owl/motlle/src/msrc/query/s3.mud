/*
  select nodeid, parent, light, ... sample period N
*/

mhop_set_update(60);

Timer0 = fn ()
  {
    led(25);
    mhopsend(encode(vector(next_epoch(), id(), parent(), light())));
  };

settimer0(300);

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
  {
    any msg = snoop_msg();
    snoop_epoch(msg);
    if (id() == 0) send(126, msg);
  };

Intercept = fn ()
  {
    string msg = intercept_msg();

    snoop_epoch(msg);	// to advance epoch if necessary
    if (intercept2 != '())
      intercept2(msg);
  };
