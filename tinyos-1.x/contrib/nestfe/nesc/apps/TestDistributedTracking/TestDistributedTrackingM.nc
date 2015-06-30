/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author Michael Manzo <mpm@eecs.berkeley.edu>
 */

module TestDistributedTrackingM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as TrackControl;
    interface Track;
    interface Timer;
  }
} 

implementation {
  TOS_Msg cmdBuffer; 

  command result_t StdControl.init() {
    return call TrackControl.init();
  }

  command result_t StdControl.start() {
    return call TrackControl.start();
  }

  command result_t StdControl.stop() {
    return call TrackControl.stop();
  }

  event result_t Timer.fired() {
    atomic {
      dbg(DBG_USR2, "SET BACKTRACK\n"); // flag tython
      if (generic_adc_read(TOS_LOCAL_ADDRESS, 68, 0) == 2) {
	call Timer.stop();
      } else if (generic_adc_read(TOS_LOCAL_ADDRESS, 68, 0) == 1) {
	// we start 100 binary msec in the future so (hopefully) all the nodes
	// have time to get the flood of the cmd to start backtracking.
	call Track.startSingleTrackReport(((uint32_t) tos_state.tos_time) + 1024);
	call Timer.stop();
	dbg(DBG_USR2, "tracks: called startSingleTrackReport(1024)\n"); 
      }
    }
    return SUCCESS;
  }
}
