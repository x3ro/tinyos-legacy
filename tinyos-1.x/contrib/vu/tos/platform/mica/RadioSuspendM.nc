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
 * Date last modified: 12/02/02
 */

module RadioSuspendM
{
	provides interface StdControl;
}

implementation
{
	uint8_t timsk = 0x00;

	command result_t StdControl.init()
	{
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		if( timsk == 0x00 )
		{
			uint8_t a = inp(TIMSK) & ((0x01<<TOIE2)|(0x01<<OCIE2));
			if( a != 0x00 )
			{
				timsk = a;

				cbi(TIMSK, TOIE2);
				cbi(TIMSK, OCIE2);

				return SUCCESS;
			}
		}
		return FAIL;
	}

	command result_t StdControl.start()
	{
		uint8_t a = timsk;

		if( (a & (0x01<<TOIE2)) != 0 )
			sbi(TIMSK, TOIE2);

		if( (a & (0x01<<OCIE2)) != 0 )
			sbi(TIMSK, OCIE2);

		timsk = 0x00;

		return SUCCESS;
	}
}
