/* select avg(light) sample period 60s */

mhop_set_forwarding(0);
mhop_set_update(120);
settimer0(600);

spatial_add = 0;
spatial_sample = 1;
spatial_get = 2;

spatialavg = fn (function attr)
  {
    any sstate = spatialavg_make(attr);

    epoch_change = fn() spatialavg_epoch_update(sstate);
    
    vector(fn (data) spatialavg_intercept(sstate, data),
	   fn () spatialavg_sample(sstate, sstate[0]()),
	   fn () spatialavg_get(sstate))
  };

avgtemp = spatialavg(temp);

timer0 = fn ()
  {
    any avg;

    if (id() != 22)
      led(26);
    if (id())
      {
	next_epoch();
	avgtemp[spatial_sample]();
      };
    avg = avgtemp[spatial_get]();
    if (avg)
      mhopsend(encode(vector(epoch(), id(), parent(), depth(), avg)));
  };

snoop = fn ()
  snoop_epoch(decode_message(snoop_msg())[0]);
intercept = fn () 
  {
    vector fields = decode_message(intercept_msg());

    led(25);
    snoop_epoch(fields[0]);
    avgtemp[spatial_add](fields[4]);
  };
decode_message = fn (msg)
  decode(msg, vector(2, 2, 2, 2, make_string(6)));
