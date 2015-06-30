/*
   select nodeid, winavg(5, 3, light) sample period N
   (or whatever the syntax is)
*/

winavg = fn (function attr, int attr_default, int size)
  {
    vector window = make_vector(size);
    int pos = 0;

    vector_fill!(window, attr_default);

    vector(fn () // sample
	   {
	     window[pos++] = attr();
	     if (pos == size)
	       pos = 0;
	   },
	   fn () // average
	   {
	     int sum = 0, i = 0;

	     while (i < size)
	       sum += window[i++];

	     sum / size
	   })
  };
win_sample = 0;
win_avg = 1;

winlight = winavg(light, 0, 5);
winlight_count = 0;

timer0 = fn  ()
  {
    next_epoch();
    winlight[win_sample]();
    if (++winlight_count == 3)
      {
	winlight_count = 0;
	mhopsend(vector(epoch, nodeid(), winlight[win_avg]()));
      }
  };

settimer0(N / 100);
