/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 06/23/03
 */

module TestClapDetectorM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface ClapDetector;
		interface Leds;
		interface GlobalTime;
		interface DiagMsg;
	}
}

implementation
{
	command result_t StdControl.init(){
		call Leds.init();
		return SUCCESS;
	}		
	command result_t StdControl.start(){
		return SUCCESS;
	}
	command result_t StdControl.stop(){
		return SUCCESS;
	}
	
	event void ClapDetector.fired()
	{
		uint32_t time;
		call GlobalTime.getGlobalTime(&time);

		if( call DiagMsg.record() == SUCCESS )
		{
			call DiagMsg.uint8((uint8_t)TOS_LOCAL_ADDRESS);
			call DiagMsg.uint32(time);
			call DiagMsg.send();
		}
		
		call Leds.redToggle();
	}
}
