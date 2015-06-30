/*									tab:4
 *
 *
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
 * Authors:		Sarah Bergbreiter
 * Date last modified:  11/11/03
 *
 * UltrasoundTransmitter sends an ultrasound chirp (radio packet + ultrasound
 * beep) at a periodic rate based on the mote ID.  If the moteID is < 1000, 
 * it will default to a rate of 1 chirp/sec.  Otherwise, the period between
 * chirps = the ID in milliseconds.
 *
 * Since this can only run on the mica2dot, I only have the red LED to 
 * play with.  Toggle red LED on timer.
 *
 */

module UltrasoundTransmitterM {
  provides interface StdControl;
  uses {
    interface UltrasonicRangingTransmitter as Transmit;
    interface Timer as BeepTimer;
    interface Leds;
  }
}
implementation{

  uint16_t timerPeriod;
  uint16_t seqNum;
  bool initRanging;

  command result_t StdControl.init() {
    if (TOS_LOCAL_ADDRESS < 10)
      timerPeriod = 1000;
    else
      timerPeriod = TOS_LOCAL_ADDRESS;
    seqNum = 0;
    initRanging = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call BeepTimer.start(TIMER_REPEAT, timerPeriod);
  }

  command result_t StdControl.stop() {
    return call BeepTimer.stop();
  }

  event result_t BeepTimer.fired() {
    call Leds.redToggle();
    seqNum++;
    call Transmit.send(TOS_LOCAL_ADDRESS,0,(uint8_t)seqNum,initRanging);
    return SUCCESS;
  }

  event void Transmit.sendDone() {
    return;
  }

}

