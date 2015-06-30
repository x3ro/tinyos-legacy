/* select nodeid, parent, expavg(2, temp) where light > 920 sample period 60s */

mhop_set_update(120);
settimer0(600);

expdecay = fn (function attr, int bits)
  {
    int running = 0;

    fn () // sample and decay
      running = running - (running >> bits) + (attr() >> bits)
  };

decaytemp = expdecay(temp, 2);

Timer0 = fn ()
  {
    if (id() != 22)
      led(26);
    next_epoch();
    if (light() > 920)
      mhopsend(encode(vector(epoch(), id(), parent(), decaytemp())));
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

