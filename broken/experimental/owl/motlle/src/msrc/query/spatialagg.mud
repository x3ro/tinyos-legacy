/* select avg(temp) where light > 100 sample period N
*/

maxdepth = 8;

spatialavg = fn (function attr, int window)
  {
    vector sum = make_vector(window), count = make_vector(window);
    int start = 0;

    add_epoch_change_handler
      (fn()
       // ensure epoch + 1 is inside the window
       if (epoch + 1 >= start + window)
       {
	 int i, shift;
	 
	 // figure out new start and how much to shift values
	 // from old epoch for the new start
	 shift = epoch + 2 - window - start;
	 start = epoch + 2 - window;
	 
	 if (shift > window)
	   shift = window;
	 else
	   {
	     i = shift;
	     while (i < window)
	       {
		 count[i - shift] = count[i];
		 sum[i - shift] = sum[i];
	       };
	   };
	 
	 // clear new values
	 i = window - shift;
	 while (i < window)
	   count[i] = sum[i] = 0;
       });
    
    add_sample = fn (int when, int n, int total)
      // check that we're keeping track of epoch 'when'
      if (when >= start && when < start + window)
	{
	  count[when - start] += n;
	  sum[when - start] += total;
	};
    
    sample = fn ()
      add_sample(epoch, 1, attr());
    
    sample_get = fn (when)
      if (when >= start)
	vector(count[when - start], sum[when - start])
      else
	false;

    vector(add_sample, sample, sample_get);
  };

spatial_add = 0;
spatial_sample = 1;
spatial_get = 2;

avgtemp = spatialavg(temp, maxdepth);

timer0 = fn ()
  {
    int send_epoch;
    any val;
    
    next_epoch();
    avgtemp[spatial_sample]();
    
    send_epoch = epoch - (maxdepth - depth());
    val = avgtemp[spatial_get](send_epoch);
    if (val)
      mhopsend(vector(send_epoch, val[0], val[1]))
  };

intercept2 = fn (msg)
  {
    vector v = decode(msg, vector(2, 2, 2));
    avgtemp[spatial_add](v[0],v[1], v[2]);
    false			// suppress forwarding
  };

settimer0(N / 100);
