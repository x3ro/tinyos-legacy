// $Id: TestDimmerM.nc,v 1.2 2004/10/21 16:32:19 jwhui Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module TestDimmerM {
  provides {
    interface StdControl;
  }
  uses {
    interface DimmerControl;
    interface Leds;
    interface ReceiveMsg;
    interface Timer;
  }
}

implementation {

  uint8_t level;
  bool    goUp;

  command result_t StdControl.init() {
    level = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    goUp = TRUE;
    call Timer.start(TIMER_REPEAT, 8);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    call Leds.redToggle();
    if (level == 255)
      goUp = FALSE;
    else if (level == 0)
      goUp = TRUE;
    if (goUp)
      level++;
    else
      level--;
    call DimmerControl.setLevel(level);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pMsg) {

    DimmerMsg *rxMsg = (DimmerMsg*)pMsg->data;

    call Leds.greenToggle();

    call Timer.stop();
    call Timer.start(TIMER_REPEAT, rxMsg->level);
    //    call DimmerControl.setLevel(rxMsg->level);

    return pMsg;

  }

}
