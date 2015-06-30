/*
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Author: Tom Parker
 * This module provides the byte-level RadioSPI interface to the TOSSIM radio
 */

module RadioSPIM
{
	provides {
		interface RadioSPI;
		interface RadioSettings;
	}
	uses {
		interface SpiByteFifo;
		interface UARTDebug as Debug;
	}
}

implementation
{	
	#include "TMACEvents.h"
	
	typedef enum { LL_SLEEP=1, LL_IDLE, LL_TRANSMIT=4, LL_INIT, LL_ENDING } RadioState;
	RadioState state;
	
	command result_t RadioSPI.send(uint8_t data)
	{
		if (state!=LL_TRANSMIT)
			call RadioSPI.txMode();
		dbg(DBG_RADIO,"Outgoing data %d (state=%d)\n",data,state);
		return call SpiByteFifo.send(data);
	}

	command result_t RadioSPI.sleep()
	{
		call SpiByteFifo.idle();
		state = LL_SLEEP;
		//call Debug.txStatus(_LL_RADIO_STATE,state);
		return SUCCESS;
	}

	command result_t RadioSPI.init()
	{
		call SpiByteFifo.phaseShift();
		state = LL_INIT;
		//call Debug.txStatus(_LL_RADIO_STATE,state);
		return SUCCESS;
	}

	command result_t RadioSPI.idle()
	{
		if (state == LL_TRANSMIT)
		{	
			state = LL_ENDING;
			//call Debug.txStatus(_LL_RADIO_STATE,state);
			return SUCCESS;
		}
		if (state == LL_SLEEP)
			call SpiByteFifo.phaseShift();
		call SpiByteFifo.rxMode();
		state = LL_IDLE;
		//call Debug.txStatus(_LL_RADIO_STATE,state);
		return SUCCESS;
	}

	command result_t RadioSPI.txMode()
	{
		state = LL_TRANSMIT;
		//call Debug.txStatus(_LL_RADIO_STATE,state);
		return call SpiByteFifo.txMode();
	}
	
	event result_t SpiByteFifo.dataReady(uint8_t data)
	{
		dbg(DBG_RADIO,"Incoming data %d (state=%d)\n",data,state);
		if (state == LL_ENDING)
			call RadioSPI.idle();
		if (state!=LL_TRANSMIT)
			signal RadioSPI.dataReady(data,TRUE);
		else
			signal RadioSPI.xmitReady();
		return SUCCESS;
	}
	
	inline command uint16_t RadioSPI.getRSSI()
	{
		return 0;
	}

	inline command result_t RadioSettings.SetRFPower(uint8_t power)
	{
		return SUCCESS;
	}
}
