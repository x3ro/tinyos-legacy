/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Joe Polastre
 * Authors:   Kevin Klues (adaptation for eyesNodes)
 *
 * $Id: BusArbitrationM.nc,v 1.1 2005/01/26 14:13:59 klueska Exp $
 */

module BusArbitrationM {
  provides {
    interface BusArbitration[uint8_t id];
    interface StdControl;
  }
}
implementation {

  uint8_t state;
  uint8_t busid;
  bool isBusReleasedPending;
  enum { BUS_IDLE, BUS_BUSY, BUS_OFF };
  
  void ReleaseBus(uint8_t i) {
    uint8_t currentstate;
    atomic currentstate = state;
    signal BusArbitration.busReleased[i]();
  }

  task void busReleased() {
    uint8_t i;
    uint8_t currentBusid;
    // tell everyone the bus has been released
    atomic isBusReleasedPending = FALSE;
    atomic currentBusid = busid;
    for (i = 0; i < currentBusid; i++) {
      ReleaseBus(i);
    }
    for (i = currentBusid+1; i < uniqueCount("BusArbitration"); i++) {
      ReleaseBus(i);
    }
    ReleaseBus(currentBusid);
  }
  
  task void busRequested() {
    uint8_t currentstate, currentBusid;
    atomic currentstate = state;
    atomic currentBusid = busid;
    if (currentstate != BUS_IDLE)
      // Tell the owner of the bus that the bus has been requested
      signal BusArbitration.busRequested[currentBusid]();
  }
 
  command result_t StdControl.init() {
    state = BUS_OFF;
    isBusReleasedPending = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    if (state == BUS_OFF) {
      state = BUS_IDLE;
      isBusReleasedPending = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t StdControl.stop() {
    if (state == BUS_IDLE) {
      state = BUS_OFF;
      isBusReleasedPending = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t BusArbitration.getBus[uint8_t id]() {
    bool gotbus = FALSE;
    atomic {
      if (state == BUS_IDLE) {
        state = BUS_BUSY;
        gotbus = TRUE;
        busid = id;
      }
    }
    if (gotbus)
      return SUCCESS;
    post busRequested();
    return FAIL;
  }
 
  async command result_t BusArbitration.releaseBus[uint8_t id]() {
    atomic {
      if ((state == BUS_BUSY) && (busid == id)) {
        state = BUS_IDLE;

	// Post busReleased inside the if-statement so it's only posted if the
	// bus has actually been released.  And, only post if the task isn't
	// already pending.  And, it's inside the atomic because
	// isBusReleasedPending is a state variable that must be guarded.
	if( (isBusReleasedPending == FALSE) && (post busReleased() == TRUE) )
	  isBusReleasedPending = TRUE;

      }
    }
    return SUCCESS;
  }

  default event result_t BusArbitration.busReleased[uint8_t id]() {
    return SUCCESS;
  }
  
  default event result_t BusArbitration.busRequested[uint8_t id]() {
    return SUCCESS;
  }
}

