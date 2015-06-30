/* equivalent TinyDB query:
select avg(temp) from ?? sample period 60s
*/

settimer0(600);       // Fire Timer0 every epoch (60s)
mhop_set_update(120); // Update multihop route every 2min

// 'spatialavg(f)' returns an "object" with methods for 
// performing spatial averaging of f. The methods are:
//   spatial_sample: measure f locally
//   spatial_agg: include results from a child
//   spatial_get: get completed results for this subtree
//     (as a string of length spatialavg_length, ready for transmission)
// An "object" is just a vector with functions as its elements.
avgtemp = spatialavg(temp);

timer0_handler = fn  ()
  {
    next_epoch();
    avgtemp[spatial_sample]();
    mhopsend(encode(vector(epoch(), avgtemp[spatial_get]())));
  };

// decode messages heard and:
// - update epoch if necessary
// - contribute aggregate summaries from children to our summary
snoop_handler = fn ()
  snoop_epoch(decode_message(snoop_msg())[0]);
intercept_handler = fn () 
  {
    vector fields = decode_message(intercept_msg());
    snoop_epoch(fields[0]);
    avgtemp[spatial_agg](fields[1]);
  };
decode_message = fn (msg)
  decode(msg, vector(2, make_string(spatialavg_length)));
