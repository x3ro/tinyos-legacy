/*
   select nodeid, expdecay(temp, 0.8) where light > 100 sample period N
   (or whatever the syntax is)
*/

expdecay = fn (function attr, int decayN, int decayD)
  {
    int running = 0;

    fn () // sample and decay
      {
	running = (running * decayN) / decayD + attr();
	running - (running * decayN) / decayD
      }
  };

decaytemp = expdecay(temp, 4, 5);

timer0 = fn  ()
  {
    next_epoch();
    if (light() > 100)
      mhopsend(vector(epoch, nodeid(), decaytemp()));
  };

settimer0(N / 100);
