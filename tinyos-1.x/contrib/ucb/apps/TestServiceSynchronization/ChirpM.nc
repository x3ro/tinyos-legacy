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

/* Authors:   David Culler
 * History:   created 10/5/2000
 *
 *
 */

/**
 * The Chirp application periodically sends a broadcast packet over the
 * radio using a timer.  The packet contains the current photo sensor
 * reading.
 */

includes TosServiceSchedule;
module ChirpM
{
  provides interface StdControl;
  uses {
    interface Leds;
    interface Timer;
    interface ADC;
    interface StdControl as ADCControl;
    interface StdControl as CommControl;
    interface StdControl as TimerControl;
    interface SendMsg as SendChirpMsg;
    interface ReceiveMsg as ReceiveChirpMsg;
    interface StdControl as SchedCtl;
    interface ServiceScheduler;
    interface TimeSet;
  }
}
implementation
{
  /**
   * stop sending chirps when MAX_CHIRPS has been reached
   */
  enum {
    MAX_CHIRPS = 100
  };

  uint8_t counter;		/* Component counter counter */
  TOS_Msg msg;			/* Message to be sent out */
  bool sendPending;		/* Variable to store counter of buffer*/
  /**
   * Chirp initialization: <p>
   * turn on the LEDs<br>
   * initialize lower components.<br>
   * initialize component counter, including constant portion of msgs.<br>
   *
   * @return the result from <code>ADCControl.init()</code> 
   *         and <code>CommControl.init()</code>
   */
  command result_t StdControl.init() {
      result_t ret1;
      result_t ret2;
      result_t ret3;
      tos_service_schedule s;

    call Leds.init();
    call Leds.redOn();
    call Leds.greenOn();
    call Leds.yellowOn();
    counter = 0;
    sendPending = FALSE;
    msg.data[0] = TOS_LOCAL_ADDRESS; //record your id in the packet.
    dbg(DBG_BOOT, "CHIRP initialized\n");
    ret1 = call ADCControl.init();
    ret2 = call TimerControl.init();
    ret3 = call CommControl.init();

    // surrogate time sync
    s.start_time.low32 = 0;
    s.start_time.high32 = 0;
    call TimeSet.set(s.start_time);
    // hardwired schedule
    s.start_time.low32 = 1;
    s.start_time.low32 <<= 20;
    s.on_time = 10;
    s.off_time = 10;
    s.flags = 0;
    call SchedCtl.init();
    call SchedCtl.start();
    call ServiceScheduler.reschedule(0, s);
    return rcombine3(ret1, ret2, ret3);
  }

  /**
   * Chirp start starts the Timer
   *
   * @return the result from <code>Timer.start()</code>
   */
  command result_t StdControl.start() {
      call ADCControl.start();
      call CommControl.start();
    return call Timer.start(TIMER_REPEAT, 1000);
  }

  /**
   * Chirp stop stops the Timer
   *
   * @return the result from <code>Timer.stop()</code>
   */
  command result_t StdControl.stop() {
    call CommControl.stop();
    call ADCControl.stop();
    return call Timer.stop();
  }

  /** Timer Event Handler:<br>
   * Signaled at end of each clock interval.
   * When a Timer event occurs, sample the photo sensor.
   *
   * @return SUCCESS always
   */
  event result_t Timer.fired() {
      //call ADCControl.start();
      //call CommControl.start();
    if (counter < MAX_CHIRPS && !sendPending)
      {
	sendPending = TRUE;
	counter++;
	//turn on the red led while data is being read.
	call Leds.redOn();
	call ADC.getData(); /* start data reading */
      }
    return SUCCESS;
  }

  /**
   * Triggers completion activities such as turning the Green LED off
   * and setting the <code>sendPending</code> variable.
   */
  void sendComplete() {
    call Leds.greenOff();
    call Leds.yellowOff();
    sendPending = FALSE;
  }

  /**
   * Handler for subsystem data event, fired when data ready from the photo
   * sensor.  Put int data in a broadcast message to handler 0.
   * Post msg to be sent over the radio.
   *
   * @param data the value of the photo sensor
   *
   * @return SUCCESS always
   */
  event result_t ADC.dataReady(uint16_t data) {
    call Leds.redOff();
    call Leds.greenOn(); /* Green LED while sending */
  
    msg.data[1] = (data >> 8) & 0xff;
    msg.data[2] = data & 0xff;
    if (call SendChirpMsg.send(TOS_BCAST_ADDR, 3, &msg) == FAIL)
      sendComplete();

    return SUCCESS;
  }

  /**
   * Notification that the message has been sent over the radio
   *
   * @param sent the message buffer of the sent message
   * @param success the result of sending the message
   *
   * @return SUCCESS always
   */
  event result_t SendChirpMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    //check to see if the message that finished was yours.
    //if so, then clear the sendPending flag.
    if (&msg == sent)
      sendComplete();

    return SUCCESS;
  }

  /**
   * Message Handler for Chirp packets.  When a new packet comes in,
   * blink the yellow LED.
   *
   * @param data msg buffer passed (incoming packet)
   *
   * @return msg buffer to be reused
   */
  event TOS_MsgPtr ReceiveChirpMsg.receive(TOS_MsgPtr data) {
    call Leds.yellowToggle();
    return data;
  }
}
