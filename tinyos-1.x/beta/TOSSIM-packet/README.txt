TOSSIM Packet Level Simulation project

- This directory contains components that engage a prototype packet-level
  TOSSIM simulation. Bandwidth, etc., is roughly based on the CC1000
  radio. Many of the constants (e.g. backoff) are a bit arbitrary right now
  and so may not reflect the current real radio implementation.

- To use this instead of standard bit-level simulation, add the following
  line to your application Makefile:

  PFLAGS += -I%T/../beta/TOSSIM-packet

- There is also an update to LossyBuilder, which can build packet
  topologies. Use the -packet option. You need to copy the two
  java files into net/tinyos/sim and net/tinyos/sim/lossy.  

- Several other minor additions to TOSSIM are included here, such as
  setting the random seed.
  
- Project members/groups:
         Philip Levis (UC Berkeley)

- General Action Items:
     * Incorporate shadowing phenomenon (better collision model)
     * Investigate radio constants and bring closer to reality
     * Incorporate ACKs, timestamps, other goodies
     * Run benchmarks to compare with empirical data

- Noted changes
  3.15.04: Fixed several major bugs discovered by Jonathan Hui
  3.16.04: Fixed idle channel detection bug
  3.16.04: Added small performance improvement (append, not prepend, to list)

- People to email on changes:
   Phil Levis <pal@cs.berkeley.edu>
   Matt Welsh <mdw@eecs.harvard.edu>


