/* select nodeid, parent, light sample period 60s */

mhop_set_update(20);
settimer0(100);

Timer0 = fn ()
  {
    if (id() != 22)
      led(26);
    mhopsend(encode(vector(next_epoch(), id(), parent(), light())));
  };

snoop = fn ()
  {
    any msg = snoop_msg();
    heard(msg);
    if (id() == 0) send(126, msg);
  };
intercept = fn ()
  heard(intercept_msg());

heard = fn (msg)
  {
    vector v = decode(msg, vector(2));
    snoop_epoch(v[0]);
  };

