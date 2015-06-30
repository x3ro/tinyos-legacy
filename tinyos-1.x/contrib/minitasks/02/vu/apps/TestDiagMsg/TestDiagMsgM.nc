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
 * Date last modified: 2/20/03
 */

includes DiagMsg;

module TestDiagMsgM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface DiagMsg;
		interface Leds;
	}
}

implementation
{
	uint8_t counter;

	command result_t StdControl.init()
	{
		call Leds.init();

		counter = 0;

		return SUCCESS;
	}

	task void send()
	{
		// artificial delay to get around a bug in TinyOS
		uint16_t i = 1000;
		while( --i != 0 )
			TOSH_wait();

		if( call DiagMsg.record() == SUCCESS )
		{
			call Leds.redToggle();

			call DiagMsg.str("test");
			call DiagMsg.uint8(counter++);
			call DiagMsg.int16(1973);
			call DiagMsg.str("XY");
			call DiagMsg.real(12.345);
			call DiagMsg.chr('Z');
			call DiagMsg.uint32(123456789);
			call DiagMsg.token(DIAGMSG_END);
			call DiagMsg.send();
		}

		post send();
	}

	command result_t StdControl.start()
	{
		post send();

		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
}
