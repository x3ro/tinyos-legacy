/* select avg(light) sample period 60s */

mhop_set_forwarding(0);
mhop_set_update(120);
settimer0(600);

spatialavg = fn (function attr)
  {
    any sstate = spatial_make(attr, vector(0, 0)), add;

    add = fn (when, n, s)
      {
	any v = spatial_get(sstate, when);

	if (v)
	  {
	    v[0] += n;
	    v[1] += s;
	  };
      };
    
    sample = fn ()
      add(epoch(), 1, attr());
    
    intercept = fn (string data)
      {
	vector summary = decode(data, vector(2, 2, 2));
	add(summary[0], summary[1], summary[2]);
      };
    
    epoch_change = fn() spatialavg_epoch_update(sstate);
    
    vector(fn (data) spatialavg_intercept(sstate, data),
	   fn () spatialavg_sample(sstate, sstate[0]()),
	   fn () if (spatial_send()) 
	   encode(vector(spatial_send(), encode(spatial_get(spatial_send()))))
	   else 0)
  };

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
