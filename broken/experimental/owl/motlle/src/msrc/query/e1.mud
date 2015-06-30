/* select nodeid, parent, light sample period 60s */

ep = 0;
suppress = 0;
mhop_set_update(120);
settimer0(600);

Timer0 = fn ()
  {
    if (id() != 22)
      led(26);
    if (!suppress)
      ep = ep + 1;
    suppress = 0;
    mhopsend(encode(vector(ep, id(), parent(), light())));
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
    if (v[0] > ep)
      {
	ep = v[0];
	suppress = 1;
      }
  };

