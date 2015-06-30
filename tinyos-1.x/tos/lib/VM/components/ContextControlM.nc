// $Id: ContextControlM.nc,v 1.3 2004/07/15 02:58:38 scipio Exp $

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
 * Copyright (c) 2004-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Date last modified:  11/29/03
 *
 */

/**
 * This component filters packet receptions based on AM addressing
 * requirements. Packets are filtered on two attributes: the
 * destination address must either be the local address or the
 * broadcast address, and the group ID must match the local group ID.
 *
 * @author Philip Levis
 * @date 11/29/03
*/

includes AM;

module ContextControlM {

  provides interface StdControl;
	
  uses {
    interface StdControl as SubControl;
    interface Timer;
    interface Intercept;
    interface RouteControl;

    command result_t triggerStart();
    command result_t triggerMerge(MateDataBuffer* buf);
    command result_t triggerOverhear(MateDataBuffer* buf);
    command result_t triggerResolve();
		
  }
}


implementation {

  enum {
    MAX_DEPTH = 8,
    INIT_PERIOD = 16,
  };

  enum {
    STATE_INIT = 1,
    STATE_IDLE = 2,
    STATE_MERGE = 3,
  } ControlState;
	
  uint8_t currentDepth;
  uint8_t counter;
  uint8_t state;
	
  command result_t StdControl.init() {
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    state = STATE_INIT;
    counter = 0;
    currentDepth = 8;
    call Timer.start(TIMER_REPEAT, 2048);
    return call SubControl.start();
  }
	
  command result_t StdControl.stop() {
    call Timer.stop();
    return call SubControl.stop();
  }

  event result_t Timer.fired() {
    counter++;
    //dbg(DBG_TEMP, "ContextControlM: Timer ticked, counter is %i, state is %i, current depth is %i\n", (int)counter, (int)state, (int)currentDepth);
    if (state == STATE_INIT) {
      if (counter >= INIT_PERIOD) {
	state = STATE_IDLE;
	currentDepth = call RouteControl.getDepth();
	counter = 0;
      }
    }
		
    else if (state == STATE_IDLE) {
      if (counter < (MAX_DEPTH - currentDepth - 1)) { // Periods before ours
	state = STATE_MERGE;
      }
      if (counter >= MAX_DEPTH) {
	counter = 0;
	currentDepth = call RouteControl.getDepth();
	if (call triggerStart() != SUCCESS) { // End/Start of period
	  //dbg(DBG_TEMP, "ContextControl: Could not trigger start.\n");
	}
      }
    }
		
    else if (state == STATE_MERGE) {
      if (counter >= (MAX_DEPTH - currentDepth - 1)) {
	if (call triggerResolve() != SUCCESS) { 
	  //dbg(DBG_TEMP, "ContextControl: Could not trigger resolve.\n");
	}
	state = STATE_IDLE;
      }
    }
		
    else {
      //dbg(DBG_TEMP, "ContextControl: Invalid state: %i\n", (int)state);
    }
    return SUCCESS;
  }

  event result_t Intercept.intercept(TOS_MsgPtr msg, void* payload, uint16_t len) {
    if (state == STATE_MERGE) {
      MateDataBuffer* buf = (MateDataBuffer*)payload;
      //     dbg(DBG_TEMP, "ContextControl: Triggering merge.\n");
      call triggerMerge(buf);
    }
    else {
      //dbg(DBG_TEMP, "ContextControl: Received packet in non-merge phase.\n");
    }
    return FAIL; // Do not forward the packet
  }

  default command result_t triggerOverhear(MateDataBuffer* buf) {
    return SUCCESS;
  }
	
	
}
