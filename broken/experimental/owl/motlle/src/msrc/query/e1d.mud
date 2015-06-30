/* select nodeid, parent, light sample period 60s */

mhop_set_update(120);
settimer0(600);

Timer0 = fn ()
  {
    mhopsend(encode(vector(next_epoch(), id(), parent(), light())));
  };

snoop = fn ()
  heard(snoop_msg());
intercept = fn ()
  heard(intercept_msg());

heard = fn (msg)
  {
    vector v = decode(msg, vector(2));
    snoop_epoch(v[0]);
  };
