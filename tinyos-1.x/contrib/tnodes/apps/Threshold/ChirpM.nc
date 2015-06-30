// $Id: ChirpM.nc,v 1.1 2006/03/06 10:07:40 palfrey Exp $

/*									tab:4
 * CHIRP.c - periodically emits an active message containing light reading
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:   David Culler
 * History:   created 10/5/2000
 *
 *
 */

/**
 * The Chirp application periodically sends a broadcast packet over the
 * radio using a timer.  The packet contains the current photo sensor
 * reading.
 * @author David Culler
 */

module ChirpM
{
	provides interface StdControl;
	uses
	{
		interface Leds;
		interface Timer;
		interface ADC;
		interface StdControl as ADCControl;
		interface StdControl as CommControl;
		interface SendMsg as SendChirpMsg;
		//interface ReceiveMsg as ReceiveChirpMsg;
		interface UARTDebug as Debug;
		interface MACTest;
	}
}

implementation
{

#include "TMACEvents.h"
#include "dbg.h"

#if 0
  /**
   * stop sending chirps when MAX_CHIRPS has been reached
   */
	enum
	{
		MAX_CHIRPS = 100
	};
#endif

#define THRESHOLD 0x280

	enum {RED=1,GREEN=2,YELLOW=4};

	uint8_t counter;			/* Component counter counter */
	TOS_Msg msg;				/* Message to be sent out */
	bool sendPending;			/* Variable to store counter of buffer */
	bool havesent;

	#define VALUE_COUNT 200
	uint16_t old_values[VALUE_COUNT];
	uint16_t index;
	uint32_t total;
  /**
   * Chirp initialization: <p>
   * turn on the LEDs<br>
   * initialize lower components.<br>
   * initialize component counter, including constant portion of msgs.<br>
   *
   * @return the result from <code>ADCControl.init()</code> 
   *         and <code>CommControl.init()</code>
   */
	command result_t StdControl.init()
	{
		call Leds.init();
		call Leds.yellowOn();
		call Debug.txStatus(_LED_SET,YELLOW);
		//call Leds.redOn();
		//call Debug.txStatus(_LED_SET,RED);
		call Leds.greenOn();
		call Debug.txStatus(_LED_SET,GREEN);
		counter = 0;
		atomic 
		{
			int i;
			for (i=0;i<VALUE_COUNT;i++)
				old_values[i] = 0;
			sendPending = FALSE;
			havesent = FALSE;
			total = 0;
			index = 0;
			msg.data[0] = TOS_LOCAL_ADDRESS;	//record your id in the packet.
		}
		dbg(DBG_BOOT, "CHIRP initialized\n");
		return rcombine(  call ADCControl.init(),call CommControl.init()) ;
	}

  /**
   * Chirp start starts the Timer
   *
   * @return the result from <code>Timer.start()</code>
   */
	command result_t StdControl.start()
	{
		call Debug.setFlags(7|8);
		return call Timer.start(TIMER_REPEAT, 50);
	}

  /**
   * Chirp stop stops the Timer
   *
   * @return the result from <code>Timer.stop()</code>
   */
	command result_t StdControl.stop()
	{
		return call Timer.stop();
	}

  /** Timer Event Handler:<br>
   * Signaled at end of each clock interval.
   * When a Timer event occurs, sample the photo sensor.
   *
   * @return SUCCESS always
   */
	event result_t Timer.fired()
	{
		dbg(DBG_LED,"counter = %d, sendPending = %d\n",counter,sendPending);
		if (/*counter < MAX_CHIRPS && */!sendPending)
		{
			atomic sendPending = TRUE;
			//counter++;
			call ADC.getData();	/* start data reading */
		}
		return SUCCESS;
	}

  /**
   * Triggers completion activities such as turning the Green LED off
   * and setting the <code>sendPending</code> variable.
   */
	void sendComplete()
	{
		/*call Debug.txStatus(_LED_UNSET,GREEN);
		call Leds.greenOff();*/
		atomic sendPending = FALSE;
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
	async event result_t ADC.dataReady(uint16_t data)
	{
		double threshold;
		atomic {
			total -= old_values[index];
			old_values[index] = data;
			total += data;
			index++;
			if (index == VALUE_COUNT)
				index = 0;
		}
		threshold = (total/VALUE_COUNT)*0.95;
		
		call Debug.tx16status(__RADIO_TEST_RECV,data);
		if ((havesent && data<threshold) || (!havesent && data>=threshold))
		{
			sendComplete();
			return SUCCESS;
		}
		if (havesent && data>=threshold)
		{
			atomic havesent = FALSE;
			call Leds.greenOff();
			sendComplete();
			return SUCCESS;
		}
			
		
		call Debug.txStatus(_LED_TOGGLE,GREEN);

		atomic
		{
			//data = (74<<8)+75;
			msg.data[1] = (data >> 8) & 0xff;
			msg.data[2] = data & 0xff;
		}
		if (call SendChirpMsg.send(0, 3, &msg) == FAIL)
			sendComplete();
		call Leds.greenOn();	/* Green LED while below threshold */
		atomic havesent = TRUE;

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
	event result_t SendChirpMsg.sendDone(TOS_MsgPtr sent, result_t success)
	{
		//check to see if the message that finished was yours.
		//if so, then clear the sendPending flag.
		if (&msg == sent)
			sendComplete();

		return SUCCESS;
	}

	event void MACTest.MACSleep()
	{
		call Leds.yellowOff();
	}

	event void MACTest.MACWakeup()
	{
		call Leds.yellowOn();
	}
}
