TOSSIM power estimation

- This directory contains replacement components that provide power
  simulation under TOSSIM.

- Project members:
	  Victor Shnayder (Harvard), <shnayder at eecs.harvard.edu>
	  Mark Hempstead (Harvard), <mhempste at eecs.harvard.edu>
	  Bor-rong Chen (Tufts), <brchen at eecs.tufts.edu>
	  Matt Welsh (Harvard), <mdw at eecs.harvard.edu>


- Quickstart:

See http://www.eecs.harvard.edu/~shnayder/ptossim/ for complete
documentation.

0) CAVEAT: this is beta code.  There are most likely bugs.  If you
   find one, or just need help, email shnayder at eecs.harvard.edu.

1) If you want to use the default (old) radio stack: add the following
   line to your application Makefile:

  PFLAGS += -I%T/../beta/TOSSIM-power/src

  If you want to use the mica2 radio stack, include the following two
  lines:

  PFLAGS += -I%T/../beta/TOSSIM-power/CC1000Radio 
  PFLAGS += -I%T/../beta/TOSSIM-power/src

  Note that you only want this when compiling for pc, not for mica2

2) recompile

3) make sure DBG includes USR1.  If you don't need any other debugging
   messages, this reduces to (for the appropriate shell):
   bash$ export DBG=usr1
   tcsh% setenv DBG usr1

4) run main.exe with the -p flag and save the output to a file.  For
   example 

   ./build/pc/main.exe -t=60 -p 10 > myapp.trace

5) run postprocess.py on the resulting trace:
   
   ./scripts/postprocess.py --sb=0 --em data/mica2_energy_model.txt myapp.trace

   The --sb parameter specifies whether to assume that the motes have
   a sensor board attached.  The --em parameter specifies the energy
   model.  Run postprocess.py --help for details on other options.

Email shnayder at eecs.harvard.edu if you have problems or questions.