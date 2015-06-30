/* select avg(light) sample period 60s */

mhop_set_forwarding(0);
mhop_set_update(120);
settimer0(600);

avgtemp = spatialavg(temp);

timer0 = fn ()
  {
    any avg;

    if (id())
      {
	next_epoch();
	avgtemp[1]();
      };
    avg = avgtemp[2]();
    if (avg)
      mhopsend(encode(vector(epoch(), avg)));
  };

snoop = fn ()
  snoop_epoch(decode_message(snoop_msg())[0]);
intercept = fn () 
  {
    vector fields = decode_message(intercept_msg());

    snoop_epoch(fields[0]);
    avgtemp[0](fields[1]);
  };
decode_message = fn (msg)
  decode(msg, vector(2, make_string(6)));
