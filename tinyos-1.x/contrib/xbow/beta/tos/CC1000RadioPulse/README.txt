CC1000 Radio Beta Project

- This directory houses a CC1000 based radio stack for beta testing
  new radio features/capabilities/interfaces for eventuall rollup into
  the standard release

- Project members/groups:
	  IRB (Phil Buonadonna)
	  UCB (Joe Polastre)
	  UCLA (Vladimir Bychkovsky)
          USC/ISI

- General Action Items:
  * Create a new interface for radio hooks
  * Integrate interface into the CC1000RadioIntM data path
  * Add an interface for bit-level timesync and provide default (empty)
    handlers

- Joe's Action Items:
  * RSSI sampling to determine if radio is busy based on noise analysis
    (see graphs at www.cs.berkeley.edu/~polastre/projects/radio/
  * Low power listening based on RSSI filtering
  * Cyclical transmission of packets for low duty cycle operation during
    low power listening

- People to email on changes:
  Phil Buonadonna <pbuonado@intel-research.net>
  Joe Polastre <polastre@cs.berkeley.edu>
  Wei Ye <weiye@isi.edu>
  Vladimir Bychkovsky <vlad@lecs.cs.ucla.edu>
