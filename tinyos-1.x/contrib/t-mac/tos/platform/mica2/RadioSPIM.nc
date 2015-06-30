/*
 * Copyright (c) 2002-2004 the University of Southern California
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
 * Author: Wei Ye (S-MAC implementation), Tom Parker (T-MAC Modifications)
 * This module provides the byte-level RadioSPI interface to the mica2 radio
 */

module RadioSPIM
{
	provides 
	{
		interface RadioSPI;
		interface RadioSettings;
	}
	uses {
		interface SpiByteFifo;
		interface StdControl as CC1000StdControl;
		interface CC1000Control;
		interface ADCControl;
		interface ADC as RSSIADC;
		interface UARTDebug as Debug;
	}
}

#include "TMACEvents.h"
#include <PhyConst.h>

implementation
{
	typedef enum { LL_SLEEP=1, LL_IDLE, LL_TRANSMIT, LL_INIT, LL_END_TX } RadioState;

	#define XMIT_BUF_LEN 4
	#define ADV(x) x = (((x+1) >= XMIT_BUF_LEN) ? 0 : x+1)  // from TXMAN.c
	uint8_t xmitBuf[XMIT_BUF_LEN];
	uint8_t xmitHead;
	uint8_t xmitTail;
	uint8_t xmitBufCount;
	uint8_t discardBytes;
	
	RadioState state;
	uint16_t usRSSIVal;
#ifdef TMAC_DEBUG	
	uint16_t oRSSI;
#endif
	uint8_t validCount;
	bool adc_proc;
	void RSSIused();
	
	bool bInvertRxData;	// data inverted

	command result_t RadioSPI.init()
	{
		//RadioState tState;
		call SpiByteFifo.initSlave();
		call CC1000StdControl.init();
		call CC1000Control.SelectLock(0x9);
		atomic state = LL_INIT;
		atomic adc_proc = FALSE;
		RSSIused();
		//atomic tState = state;
		//call Debug.txStatus(_LL_RADIO_STATE, tState);
		atomic bInvertRxData = call CC1000Control.GetLOStatus();  //Do we need to invert Rcvd Data?
	    call ADCControl.bindPort(TOS_ADC_CC_RSSI_PORT,TOSH_ACTUAL_CC_RSSI_PORT);
    	call ADCControl.init();
		atomic {
			xmitBufCount = 0;
			xmitHead = 0;
			xmitTail = 0;
		}
		//call Debug.init(7);
		call CC1000StdControl.start();
		call CC1000Control.BIASOn();

		return SUCCESS;
	}

	command result_t RadioSPI.sleep()
	{
		atomic state = LL_SLEEP;
		//call Debug.txStatus(_LL_RADIO_STATE, state);
		call CC1000StdControl.stop();
		call SpiByteFifo.disableIntr();
		RSSIused();
		return SUCCESS;
	}

	command result_t RadioSPI.send(uint8_t data)
	{
		RadioState tState;
		atomic tState = state;
		if (tState == LL_SLEEP || tState == LL_INIT)
			call RadioSPI.idle();
		atomic tState = state;
		if (tState!=LL_TRANSMIT)
			call RadioSPI.txMode();
		atomic {
			xmitBuf[xmitTail] = data;
			ADV(xmitTail);
			xmitBufCount++;
		}
		//call Debug.txStatus(_LL_SEND,data);
		return SUCCESS;
	}

	command result_t RadioSPI.idle()
	{
		RadioState tState;
		atomic tState = state;
		if (tState == LL_IDLE)
			return SUCCESS;
		if (tState == LL_END_TX)
		{
			bool failMe=FALSE;
			atomic 
			{
				if (xmitBufCount == 0)
					atomic discardBytes+=TX_TRANSITION_TIME;
				else
					failMe=TRUE;
			}
			if (failMe)
				return FAIL;
		}
		if (tState == LL_TRANSMIT)
		{
			call RadioSPI.send(0x00);
			//call RadioSPI.send(0x00);
			//discardBytes+=1;
			atomic state = LL_END_TX;
			//call Debug.txStatus(_LL_RADIO_STATE, LL_END_TX);
			return SUCCESS;
		}
		if (/*state == LL_INIT || */tState == LL_SLEEP)
		{
			call CC1000StdControl.start();
			call CC1000Control.BIASOn();
		}
		call SpiByteFifo.rxMode();		// SPI to miso
		call CC1000Control.RxMode();
		
		if (tState == LL_INIT || tState == LL_SLEEP)
			call SpiByteFifo.enableIntr(); // enable spi interrupt

		//call Debug.txStatus(_LL_RADIO_OLD_STATE, state);
		atomic state = LL_IDLE;
		//call Debug.txStatus(_LL_RADIO_STATE, LL_IDLE);
		return SUCCESS;
	}

	command result_t RadioSPI.txMode()
	{
		RadioState tState;
		atomic tState = state;
		if (tState == LL_TRANSMIT)
			return SUCCESS;
		if (tState != LL_END_TX)
		{	
			//call SpiByteFifo.disableIntr();
			call CC1000Control.TxMode();
			call SpiByteFifo.txMode();
			//call SpiByteFifo.enableIntr(); // enable spi interrupt
			atomic discardBytes+=TX_TRANSITION_TIME;
		}
		//call Debug.txStatus(_LL_RADIO_OLD_STATE, state);
		atomic state = LL_TRANSMIT;
		//call Debug.txByte(0xFE);
		//call Debug.txStatus(_LL_RADIO_STATE, LL_TRANSMIT);
		//call RadioSPI.send(0x00);			
		//call RadioSPI.send(0x00);
		
		return SUCCESS;
	}
	
	
	bool discard(uint8_t data)
	{
		if (discardBytes>0) {
			discardBytes--;
			#ifdef TMAC_DEBUG
			//call Debug.tx16status(__RADIO_RSSI, oRSSI);
			/*if (bInvertRxData)
				call Debug.txStatus(_DISCARD_BYTE,~data);
			else
				call Debug.txStatus(_DISCARD_BYTE,data);*/
			#endif
			return TRUE;
		}
		else
			return FALSE; 
	}

	async event result_t SpiByteFifo.dataReady(uint8_t data)
	{
		uint8_t localdata;
		//bool manchester;
		bool valid=TRUE;
		if (bInvertRxData)
			localdata = ~data;
		else
			localdata = data;
		//manchester = call CC1000Control.GetLock();
		if (usRSSIVal > MAX_VALID_RSSI)
			valid = FALSE;
		/*if (state != LL_TRANSMIT && state!=LL_END_TX)
			if (valid)
				call Debug.tx16status(__RADIO_RSSI, usRSSIVal);*/
		
		switch(state)
		{
			case LL_END_TX:
				if (xmitBufCount == 0)
				{
					if (discard(data))
						return SUCCESS;
					call RadioSPI.idle();
					break;
				}
			case LL_TRANSMIT:
				//call Debug.txStatus(_LL_SPI_EVENT,xmitBufCount);
				if (discard(data))
					return SUCCESS;
				if(xmitBufCount > 0) 
				{
					static uint8_t byte;
					atomic
					{
						byte = xmitBuf[xmitHead];
						ADV(xmitHead);
						xmitBufCount--;
					}
					call SpiByteFifo.writeByte(byte);
					//call Debug.txStatus(_LL_REAL_SEND,byte);
				}
				else // if we've got no data to send, then shove into end_tx
					state = LL_END_TX;
				if (xmitBufCount < 2 && state!=LL_END_TX)
					signal RadioSPI.xmitReady();
				break;

			case LL_IDLE:
				if (discard(data))
					return SUCCESS;
				//call Debug.txStatus(_LL_RADIO_RECV,localdata);
				signal RadioSPI.dataReady(localdata,valid);
				break;

			// These should *never* happen, but remove compiler warnings
			case LL_INIT: 
			case LL_SLEEP:
				call Debug.txStatus(_LL_BAD_RECV, state);
				break;
		}
		RSSIused();

		return SUCCESS;
	}

	inline void RSSIused()
	{	
		#ifdef TMAC_DEBUG
		atomic oRSSI = usRSSIVal;
		#endif
		atomic 
		{
			if (state == LL_IDLE && !adc_proc)
			{
				atomic adc_proc = TRUE;
				call RSSIADC.getData();
			}
			if (validCount>0)
				validCount -=1;
			if (validCount == 0)
				usRSSIVal = 0xFFF;
		}
	}

	async event result_t RSSIADC.dataReady(uint16_t data)
	{
		atomic {
			usRSSIVal = data;
			validCount = VALID_RSSI_LIMIT;
			adc_proc = FALSE;
		}
		return SUCCESS;
	}

	inline command uint16_t RadioSPI.getRSSI()
	{
		return usRSSIVal;
	}

	inline command result_t RadioSettings.SetRFPower(uint8_t power)
	{
		return call CC1000Control.SetRFPower(power);
	}
}
