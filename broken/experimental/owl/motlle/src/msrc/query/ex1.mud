/* equivalent TinyDB query:
   select nodeid, parent, light from ?? sample period 60s */

epoch = 0;	      // The current epoch
settimer0(600);       // Fire Timer0 every epoch (60s)
mhop_set_update(120); // Update multihop route every 2min

// We define the Timer0 handler by assigning a function
// to global variable 'timer0_handler'
timer0_handler = fn ()
  // 'mhopsend' sends a message (string) over the multihop network
  // 'encode' encodes the contents of a vector as a string
  mhopsend(encode(vector(++epoch, id(), parent(), light())));

// The Intercept and Snoop handlers are run when a multihop 
// message passes through (Intercept) or is overhead (Snoop)
// by this mote. If the message is from a future epoch, we 
// advance our own epoch. 
snoop_handler = fn () heard(snoop_msg());
intercept_handler = fn () heard(intercept_msg());
heard = fn (msg)
  {
    // 'decode' decodes a string into the argument vector
    // In this case, the first 2 bytes of the string are
    // decoded into an integer.
    vector v = decode(msg, vector(2));

    if (v[0] > epoch + 1)
      epoch = v[0];
  };

