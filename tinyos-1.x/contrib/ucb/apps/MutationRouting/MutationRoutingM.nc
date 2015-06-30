/*									
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Author: August Joki <august@berkeley.edu>
 *
 *
 *
 */

includes MutationRouting;
includes MutationRoute;

module MutationRoutingM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Timer as TimerBlink;
    interface Leds;
    interface MRoute;
    interface ReceiveMsg as Receive;
  }
}

implementation {
  bool leader;

  command result_t StdControl.start() {
    if (TOS_LOCAL_ADDRESS == 0) {
      call TimerBlink.start(TIMER_REPEAT, 250);
    }
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    if (TOS_LOCAL_ADDRESS == 0) {
      call TimerBlink.stop();
    }
    return SUCCESS;
  }
  
  command result_t StdControl.init() {
    call Leds.set(0);
    leader = FALSE;
    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr packet) {
    MMsg * msg = (MMsg*)packet->data;
    uint8_t on = msg->on;
    uint32_t interval = msg->interval;
    if (on) {
      call Timer.start(TIMER_REPEAT, interval);
      //dbg(DBG_USR3, "starting timer with interval %d\n", interval);
    }
    else {
      call Timer.stop();
      //dbg(DBG_USR3, "stopping timer\n");
    }
    return packet;
  }

  event result_t Timer.fired() {
    uint8_t closestTo = generic_adc_read(TOS_LOCAL_ADDRESS, 73, 0);
    //dbg(DBG_USR3, "MutationRouting timer.fired\n");
    if (closestTo) {
      MRReport_t report;
      report.x = generic_adc_read(TOS_LOCAL_ADDRESS, 128, 0);
      report.y = generic_adc_read(TOS_LOCAL_ADDRESS, 129, 0);
      leader = TRUE;
      if (closestTo == 1) {
	call MRoute.send(MA_PURSUER1, sizeof(report), (uint8_t*) &report);
	dbg(DBG_USR3, "LEADER ELECTION: evader leader x: %d y %d\n", report.x, report.y);
      }
      else {
	dbg(DBG_USR3, "LEADER ELECTION: pursuer leader x: %d y %d\n", report.x, report.y);
	call MRoute.pursuer(MA_PURSUER1);
      }
    }
    else {
      if (leader) {
	leader = FALSE;
	dbg(DBG_USR3, "LEADER ELECTION: not leader\n");
	call MRoute.notLeader();
      }
    }
    return SUCCESS;
  }

  event result_t MRoute.sendDone(EREndpoint dest, uint8_t * data) {
    return SUCCESS;
  }

  event result_t TimerBlink.fired() {
    call Leds.redToggle();
    return SUCCESS;
  }
}
