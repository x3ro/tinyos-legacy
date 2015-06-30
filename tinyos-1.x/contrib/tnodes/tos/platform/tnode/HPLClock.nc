// $Id: HPLClock.nc,v 1.1 2006/03/06 10:07:40 palfrey Exp $

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
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Modifications for Tnodes: Tom Parker
 *
 */

// The Tnode-specific parts of the hardware presentation layer.


/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Tom Parker
 */

module HPLClock
{
	provides interface Clock;
	provides interface StdControl;
	provides interface Clock16;
}
implementation
{
	bool set_flag;
	uint8_t extScale, extInterval; /* external interval/scale values, let's pretend to be an 8-bit clock */
	/* all of the below are stored in 16-bit counter form */
	uint8_t mscale, nextScale;
	uint16_t minterval;
	uint8_t mult;

	void translateScale(uint8_t *scale,uint16_t *interval)
	{
		atomic 
		{
			switch (*scale)
			{
				case 1: /* 1 = 32768 tps*/
					//*scale = 1; /* 1 */
					mult = 244;
					break;
					
				case 2: /* 8 = 4096 tps */
					//*scale = 2; /* 8 */
					mult = 244;
					break;

				case 3: /* 32 = 1024 tps */
					//*scale = 3; /* 64 */
					mult = 122;
					break;
				
				case 4: /* 64 = 512 tps */
					//*scale = 4; /* 256 */
					mult = 61;
					break;
				
				case 5: /* 128 = 256 tps */
					*scale = 4; /* 256 */
					mult = 122;
					break;
				
				case 6: /* 256 = 128 tps */
					*scale = 5; /* 1024 */
					mult = 61;
					break;
				
				case 7: /* 1024 = 32 tps */
					*scale = 5;
					mult = 244;
					break;
			}
			*interval *= mult;
		}
	}

	command result_t StdControl.init()
	{
		uint8_t mi, ms;
		atomic
		{
			mult = 1;
			extScale = mscale = DEFAULT_SCALE;
			extInterval = minterval = DEFAULT_INTERVAL;
			translateScale(&mscale,&minterval);
			set_flag = FALSE;
			mi = minterval;
			ms = mscale;
		}

		call Clock.setRate(mi, ms);
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		uint8_t mi;
		atomic mi = minterval;
		call Clock.setRate(mi, 0);
		return SUCCESS;
	}

	async command void Clock.setInterval(uint8_t value)
	{
		uint16_t intv;
		uint8_t scalev;
		atomic scalev = extScale;
		atomic extInterval = value;
		intv = value;
		translateScale(&scalev,&intv);
		call Clock16.setInterval(intv);
	}

	async command void Clock16.setInterval(uint16_t value)
	{
		atomic minterval = value;
		outw(OCR3A, value);
	}

	async command void Clock.setNextInterval(uint8_t value)
	{
		uint8_t temp;
		uint16_t intv = value;
		atomic temp = extScale;
		translateScale(&temp,&intv);
		call Clock16.setNextInterval(intv);
	}

	async command void Clock16.setNextInterval(uint16_t value)
	{
		atomic
		{
			minterval = value;
			set_flag = TRUE;
		}
	}

	async command uint8_t Clock.getInterval()
	{
		return extInterval;
	}
	
	async command uint16_t Clock16.getInterval()
	{
		//return extInterval;
		return (inw(OCR3A));
	}

	async command uint8_t Clock.getScale()
	{
		return extScale;
	}

	async command uint8_t Clock16.getScale()
	{
		uint8_t ret = inb(TCCR3B);
		ret &= 0x7;
		return ret;
	}
	
	async command void Clock.setNextScale(uint8_t scale)
	{
		atomic
		{
			uint16_t intv=extInterval;
			translateScale(&scale,&intv);
		}
		call Clock16.setNextScale(scale);
	}

	async command void Clock16.setNextScale(uint8_t scale)
	{
		atomic
		{
			nextScale = scale;
			set_flag = TRUE;
		}
	}

	async command result_t Clock.setIntervalAndScale(uint8_t interval, uint8_t scale)
	{
		return call Clock.setRate(interval,scale);
	}

	async command uint8_t Clock.readCounter()
	{
		uint16_t ret = inw(TCNT3);
		ret /= mult;
		return ret;
	}

	async command uint16_t Clock16.readCounter()
	{
		return (inw(TCNT3));
	}

	async command void Clock.setCounter(uint8_t n)
	{
		outw(TCNT3,n);
	}

	async command void Clock16.setCounter(uint16_t n)
	{
		outw(TCNT3,n);
	}
	
	async command void Clock.intDisable()
	{
		cbi(ETIMSK, OCIE3A);
	}
	async command void Clock.intEnable()
	{
		sbi(ETIMSK, OCIE3A);
	}

	async command result_t Clock.setRate(char interval, char scale)
	{
		uint16_t intv = (uint8_t)interval;
		atomic extInterval = interval;
		scale &= 0x7;
		atomic extScale = scale;
		translateScale(&scale,&intv);
		return call Clock16.setRate(intv,scale);
	}

	async command result_t Clock16.setRate(uint16_t interval, uint8_t scale)
	{
		/*const uint16_t zero = 0;
		onst uint8_t trigger = 1<<6;*/
		scale &= 0x7;
		scale |= 0x8; /* set CTC mode */
		atomic
		{
			cbi(ETIMSK, OCIE3A);	//Disable TC3/A interrupt
			minterval = interval;
			mscale = scale;
			outb(TCCR3A, 1<<COM3A0); /* set TC3/A to trigger */ 
			outb(TCCR3B, scale);	
			outw(TCNT3, 0);
			outw(OCR3A, interval);
			sbi(ETIMSK, OCIE3A);
		}
		return SUCCESS;
	}

	default async event result_t Clock.fire()
	{
		return SUCCESS;
	}

	TOSH_INTERRUPT(SIG_OUTPUT_COMPARE3A)
	{
		atomic
		{
			if (set_flag)
			{
				mscale = nextScale;
				nextScale |= 0x8; /* set CTC mode */
				outb(TCCR3B,nextScale);
				set_flag = FALSE;
			}
		}
		signal Clock.fire();
	}

}
