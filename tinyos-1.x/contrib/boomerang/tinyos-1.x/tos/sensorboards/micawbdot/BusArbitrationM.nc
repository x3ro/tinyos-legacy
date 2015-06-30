/*									tab:4
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
 *
 * $Id: BusArbitrationM.nc,v 1.1.1.1 2007/11/05 19:10:40 jpolastre Exp $
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
  enum { IDLE = 0, BUSY, OFF };

  task void busReleased() {
    uint8_t i;
    // tell everyone the bus has been released
    for (i = 0; i < uniqueCount("BusArbitration"); i++) {
      if (state == IDLE) 
        signal BusArbitration.busFree[i]();
    }

  }
 
  command result_t StdControl.init() {
    state = OFF;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    if (state == OFF) {
      state = IDLE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t StdControl.stop() {
    if (state == IDLE) {
      state = OFF;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t BusArbitration.getBus[uint8_t id]() {
    bool gotbus = FALSE;
    atomic {
      if (state == IDLE) {
        state = BUSY;
        gotbus = TRUE;
        busid = id;
      }
    }
    if (gotbus)
      return SUCCESS;
    return FAIL;
  }
 
  command result_t BusArbitration.releaseBus[uint8_t id]() {
    if ((state == BUSY) && (busid == id)) {
      state = IDLE;
    }
    post busReleased();
    return SUCCESS;
  }

  default event result_t BusArbitration.busFree[uint8_t id]() {
    return SUCCESS;
  }

}

