/* equivalent TinyDB query:
select nodeid, expdecay(temp, 0.8) where light > 100 from ?? sample period 60s
*/

settimer0(600);       // Fire Timer0 every epoch (60s)
mhop_set_update(120); // Update multihop route every 2min

// 'expdecay(f, a, b)' builds a function which on every invocation
// evaluates f() and returns its exponentially decaying average
// (with constant a/b)
decaytemp = expdecay(temp, 4, 5);

timer0_handler = fn  ()
  {
    next_epoch();
    if (light() > 100)
      mhopsend(vector(epoch(), nodeid(), decaytemp()));
  };

// decode messages heard and update epoch if necessary
snoop_handler = fn () heard(snoop_msg());
intercept_handler = fn () heard(intercept_msg());
heard = fn (msg) 
  snoop_epoch(decode_message(msg, 2)[0]);
decode_message = fn (msg)
  decode(msg, vector(2, 2, 2));
