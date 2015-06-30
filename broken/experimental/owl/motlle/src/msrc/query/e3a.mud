/* select avg(light) sample period 60s */

mhop_set_forwarding(0);
mhop_set_update(120);
settimer0(600);

maxdepth = 6;
window = 2 * maxdepth;
spatial_add = 0;
spatial_sample = 1;
spatial_get = 2;

spatialavg = fn (function attr)
  {
    vector sum = make_vector(window), count = make_vector(window);
    int start = 0;
    function add, add_sample, sample, sample_get;

    vector_fill!(sum, 0);
    vector_fill!(count, 0);
    epoch_change = fn()
      // ensure epoch + 1 is inside the window
      if (epoch() + 1 >= start + window)
	{
	  int i, shift;
	 
	  // figure out new start and how much to shift values
	  // from old epoch for the new start
	  shift = epoch() + 2 - window - start;
	  start = epoch() + 2 - window;
	  
	  if (shift > window)
	    shift = window
	  else
	    {
	      i = shift;
	      while (i < window)
		{
		  count[i - shift] = count[i];
		  sum[i - shift] = sum[i];
		  i = i + 1;
		};
	    };
	  
	  // clear new values
	  i = window - shift;
	  while (i < window)
	    {
	      count[i] = sum[i] = 0;
	      i = i + 1;
	    };
	};
    
    add = fn (when, n, s)
      {
	// check that we're keeping track of epoch 'when'
	if (when >= start && when < start + window)
	  {
	    count[when - start] += n;
	    sum[when - start] += s;
	  };
      };
    
    sample = fn ()
      add(epoch(), 1, attr());
    
    add_sample = fn (string data)
      {
	vector summary = decode(data, vector(2, 2, 2));
	add(summary[0], summary[1], summary[2]);
      };
    
    sample_get = fn ()
      {
	int when = epoch() - 2 * (maxdepth - 1 - depth());

	encode(if (when >= start)
	         vector(when, count[when - start], sum[when - start])
	       else
	         vector(when, 0, 0));
      };
    
    vector(add_sample, sample, sample_get);
  };

avgtemp = spatialavg(temp);

timer0 = fn ()
  {
    if (id() != 22)
      led(26);
    if (id())
      {
	next_epoch();
	avgtemp[spatial_sample]();
      };
    if (depth() < maxdepth - 1)
      mhopsend(encode(vector(epoch(), id(), parent(), depth(), avgtemp[spatial_get]())));
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
