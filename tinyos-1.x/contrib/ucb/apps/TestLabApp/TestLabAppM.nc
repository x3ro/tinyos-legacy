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

/* Authors:             Joe Polastre
 * 
 * $Id: TestLabAppM.nc,v 1.2 2003/10/07 21:45:32 idgay Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check http://webs.cs.berkeley.edu/tos/hardware/diode_html.html
 * That page also has information for how to install the diode.
 */

includes avr_eeprom;

/**
 * Implementation of the TestSnooze application
 */
module TestLabAppM {
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Snooze;
    interface Timer as Timer1;
    interface Timer as Timer2;
    interface StdControl as TimerControl;
    interface StdControl as CommControl;
    interface StdControl as PhotoControl;
    interface StdControl as TempControl;
    interface ADCControl as VoltageControl;
    interface ADC as Photo;
    interface ADC as Temp;
    interface ADC as Voltage;
    interface SendMsg as Send;
    interface Pot;
  }
}
implementation {

  /**
   * Keeps track of how    if (call Temp.getData() == FAIL)
      sleep();
 many clock events have fired
   **/
  uint16_t photo_reading;
  uint16_t temp_reading;
  uint16_t voltage_reading;

  bool send_pending;

  TOS_Msg msg_buf;
  TOS_MsgPtr msg;

  /**
   * Invokes the Snooze.snooze() command to put the mote to sleep
   **/
  void sleep()
  {
    call PhotoControl.stop();
    call TempControl.stop();
    call TimerControl.stop();

    // sleep for 4 seconds
    call Snooze.snooze(32*4);
  }

  task void stopPhoto()
  {
    call PhotoControl.stop();
  }

  task void waitForTemp()
  {
    if (call TempControl.start() == SUCCESS)
    call Timer2.start(TIMER_ONE_SHOT, 10);
  }

  task void getTemp()
  {
    if (call Temp.getData() == FAIL)
      sleep();
  }

  /**
   * When the mote awakens, it must perform functions to begin processing again
   **/
  task void processing()
  {

     call Leds.redOn();

     call CommControl.start();
     call PhotoControl.start();
     call TimerControl.start();

     // get photo
     if (call Photo.getData() == FAIL)
       sleep();
  }

  event result_t Timer1.fired() {
    post waitForTemp();
    return SUCCESS;
  }

  event result_t Timer2.fired() {
    post getTemp();
    return SUCCESS;
  }

  event result_t Photo.dataReady(uint16_t data) {
    photo_reading = data;
    // get temperature
    post stopPhoto();
    call Timer1.start(TIMER_ONE_SHOT, 10);
    return SUCCESS;
  }

  event result_t Temp.dataReady(uint16_t data) {
    temp_reading = data;
    call TempControl.stop();
    // get voltage
    if (call Voltage.getData() == FAIL)
      sleep();
    return SUCCESS;
  }

  /**
   * Gets the next sequence number from EEPROM
   **/
  unsigned long int eeprom_next_seqno()
  {
    unsigned long int rval = 0;
    unsigned long int seqno = 0;
    unsigned char *ptr = 
	(unsigned char *) &seqno;
    
    ptr[0] = eeprom_rb(0);
    ptr[1] = eeprom_rb(1);
    ptr[2] = eeprom_rb(2);
    ptr[3] = eeprom_rb(3);

    rval = seqno++;

    eeprom_wb(0, ptr[0]);
    eeprom_wb(1, ptr[1]);
    eeprom_wb(2, ptr[2]);
    eeprom_wb(3, ptr[3]);
    
    return(rval);
  }

  event result_t Voltage.dataReady(uint16_t data) {
    voltage_reading = data;
    call Leds.redOff();
    // send data
    if (send_pending == FALSE)
    {
      unsigned long int number = eeprom_next_seqno();
      uint16_t* readings = (uint16_t*)&msg_buf.data;

      // fill the message buffer
      readings[0] = TOS_LOCAL_ADDRESS;
      readings[1] = photo_reading;
      readings[2] = temp_reading;
      readings[3] = voltage_reading;
      readings[4] = (uint16_t)(number & 0x0FFFF);
      readings[5] = (uint16_t)((number >> 16) & 0x0FFFF);

      // set the radio to the highest power
      call Pot.set(0);

      // attempt to send the reading
      send_pending = TRUE;
      if ((call Send.send(TOS_BCAST_ADDR, 12, &msg_buf)) == FAIL)
      {
        send_pending = FALSE;
	sleep();
      }
      else {
	call Leds.yellowOn();
      }

    }
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr in_msg, result_t success) {
    send_pending = FALSE;
    call Leds.yellowOff();
    sleep();
    return SUCCESS;
  }

  /**
   * Event handled when the Snooze component triggers the application
   * that it has woken up
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Snooze.wakeup() {
    post processing();
    return SUCCESS;
  }

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    call CommControl.init();
    call Leds.init();
    call PhotoControl.init();
    call TempControl.init();
    call TimerControl.init();
    send_pending = FALSE;
    return SUCCESS;
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    call CommControl.start();
    call TimerControl.start();
    post processing();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call TimerControl.stop();
    return call CommControl.stop();
  }

}

