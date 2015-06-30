// $Id: ChirpM.nc,v 1.2 2005/09/23 12:59:39 palfrey Exp $

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
		interface StdControl as CommControl;
		interface ReceiveMsg as ReceiveChirpMsg;
		interface UARTDebug as Debug;
	}
}

implementation
{

#include "TMACEvents.h"
#include "dbg.h"

  /**
   * stop sending chirps when MAX_CHIRPS has been reached
   */
	enum
	{
		MAX_CHIRPS = 100
	};

	enum {RED=1,GREEN=2,YELLOW=4};

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
		call Leds.redOn();
		call Debug.txStatus(_LED_SET,RED);
		call Leds.greenOn();
		call Debug.txStatus(_LED_SET,GREEN);
		dbg(DBG_BOOT, "CHIRP initialized\n");
		return call CommControl.init();
	}

  /**
   * Chirp start starts the Timer
   *
   * @return the result from <code>Timer.start()</code>
   */
	command result_t StdControl.start()
	{
		return SUCCESS;	
	}

  /**
   * Chirp stop stops the Timer
   *
   * @return the result from <code>Timer.stop()</code>
   */
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

  /**
   * Message Handler for Chirp packets.  When a new packet comes in,
   * blink the red LED.
   *
   * @param data msg buffer passed (incoming packet)
   *
   * @return msg buffer to be reused
   */
	event TOS_MsgPtr ReceiveChirpMsg.receive(TOS_MsgPtr data)
	{
		call Debug.txStatus(_LED_TOGGLE,RED);
		call Leds.redToggle();
		return data;
	}
}
