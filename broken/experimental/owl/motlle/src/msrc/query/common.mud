epoch = 0;
epoch_change_handlers = null;
add_epoch_change_handler = fn (function f)
  epoch_change_handlers = cons(f, epoch_change_handlers);
set_epoch = fn (newepoch)
  {
    list h = epoch_change_handlers;

    epoch = newepoch;
    while (h)
      {
	car(h)();
	h = cdr(h);
      };
    newepoch
  };
next_epoch = fn () set_epoch(epoch + 1);

snoop_epoch = fn (msg)
  {
    vector v = decode(snoop_msg(), vector(2));
    
    if (v[0] > epoch + 1)
      set_epoch(v[0]);
  };

snoop = fn ()
  snoop_epoch(snoop_msg());

intercept = fn ()
  {
    string msg = intercept_msg();

    snoop_epoch(msg); // to advance epoch if necessary
    if (intercept2 != null)
      intercept2(msg);
  };
