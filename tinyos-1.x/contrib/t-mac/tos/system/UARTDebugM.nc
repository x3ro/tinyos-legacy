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
 * Authors:	Wei Ye (S-MAC version), Tom Parker (T-MAC modifications)
 * UART debugging: this component is for sending debugging bytes thru UART
 *   Note: can't be used with any application that uses the UART, e.g. motenic
 *
 */

module UARTDebugM
{
	provides interface UARTDebug;
	uses interface StdControl as commControl;
	uses interface ByteComm as comm;
}

implementation
{
	#include "TMACEvents.h"

	#define DBG_BUF_LEN 1000
	#define ADVANCE(x) x = (((x+1) >= DBG_BUF_LEN) ? 0 : x+1)  // from TXMAN.c
	#define REDUCE(x) x = ((x == 0) ? DBG_BUF_LEN-1 : x-1)
	typedef enum {UART_IDLE=0, UART_BUSY} uart;

	// variables for UART debugging
	uart UARTState;
	uint8_t dbgBuf[DBG_BUF_LEN];
	uint16_t dbgHead;
	uint16_t dbgTail;
	uint16_t dbgBufCount;
	uint8_t flags;
	bool enabled;

	#define FLAG_RADIO 0x1
	#define FLAG_STATUS 0x2
	#define FLAG_LONGSTATUS 0x4
	#define FLAG_RADIO_TEST_ONLY 0x8
	
	command result_t UARTDebug.init(uint8_t flagset)
	{
		atomic {
			UARTState = UART_IDLE;
			dbgBufCount = 0;
			dbgHead = 0;
			dbgTail = 0;
			enabled = TRUE;
			flags = flagset;
		}

		// initialize UART
		call commControl.init();
		return SUCCESS;
	}

	command result_t UARTDebug.setFlags(uint8_t flagset)
	{
		atomic flags = flagset;
		return SUCCESS;
	}

	command result_t UARTDebug.enable()
	{
		atomic enabled = TRUE;
		return SUCCESS;
	}

	command result_t UARTDebug.disable()
	{
		atomic enabled = FALSE;
		return SUCCESS;
	}

	command result_t UARTDebug.start()
	{
		return call commControl.start();
	}

	void txextstatus(uint8_t type, uint32_t value, uint8_t len)
	{
		bool tEnabled;
		atomic tEnabled=enabled;
		if (!(flags & FLAG_LONGSTATUS) || type<=TMAC_MIN_EVENT || !tEnabled)
		{
			dbg(DBG_UART,"Dodgy incoming\n");
			return;
		}
		if (flags & FLAG_RADIO_TEST_ONLY && type!=__RADIO_TEST_RECV && type!=_RADIO_TEST_XMIT)// && type!=__RADIO_RSSI)
			return;
		atomic {
			int i;
			if (call UARTDebug.txByte(type)!=SUCCESS)
				goto end_atomic;
			for (i=len-1;i>0;i--)
			{
				if (call UARTDebug.txByte((value>>(8*i))&0xFF)!=SUCCESS)
					goto end_atomic;
			}
			call UARTDebug.txByte(value&0xFF);
			end_atomic:
		}
		return;
	}
	
	async command void UARTDebug.tx32status(uint8_t type, uint32_t value)
	{
		txextstatus(type,value,4);
	}
	
	async command void UARTDebug.tx16status(uint8_t type, uint32_t value)
	{
		txextstatus(type,value,2);
	}
	
	command void UARTDebug.txState(uint8_t byte)
	{
		bool tEnabled;
		atomic tEnabled=enabled;
		if (!(flags & FLAG_STATUS) || byte<=TMAC_MIN_EVENT || !tEnabled||(flags & FLAG_RADIO_TEST_ONLY))
			return;
		call UARTDebug.txByte(byte);
		#if defined(PLATFORM_PC) && !defined(NDEBUG)
		if (byte == INIT_STATE_DIY)
			dbg(DBG_SIMRADIO, "INIT: Entering DIY state\n");
		else if (byte == INIT_STATE_DONE)
			dbg(DBG_SIMRADIO, "INIT: Finished initialisation\n");
		else if (byte == INIT_STATE_GOT_BUT_WAIT)
			dbg(DBG_SIMRADIO, "INIT: Got a sync packet, but waiting for others\n");
		#endif
	}	
	
	async command void UARTDebug.txStatus(uint8_t type, uint8_t data)
	{
		bool tEnabled;
		atomic tEnabled=enabled;
		if (!(flags & FLAG_STATUS) || type<=TMAC_MIN_EVENT || !tEnabled)
			return;
		if (flags & FLAG_RADIO_TEST_ONLY && type!=__RADIO_TEST_RECV && type!=_RADIO_TEST_XMIT)
			return;
		call UARTDebug.txByte(type);
		call UARTDebug.txByte(data&0xFF);
		#if defined(PLATFORM_PC) && !defined(NDEBUG)
		if (type == _TMAC_STATE)
			dbg(DBG_SIMRADIO,"T-MAC state = %d\n",data);
		else if (type == _RADIO_STATE)
			dbg(DBG_SIMRADIO,"High level radio state = %d\n",data);
		#endif
		/*
		if (type == _MM_RADIO_STATE)
			dbg(DBG_SIMRADIO,"Medium level radio state = %d\n",data);
		if (type == _LL_RADIO_STATE)
			dbg(DBG_SIMRADIO,"Low level radio state = %d\n",data);*/
		return;
	}

	void printBuf()
	{
		/*int i;
		dbg(DBG_USR3,"PrintBuf: dbgHead=%d,dbgTail=%d,dbgBufCount=%d\n",dbgHead,dbgTail,dbgBufCount);
		for (i=dbgHead;i!=dbgTail;ADVANCE(i))
		{
			dbg(DBG_USR3,"Buffer at %d is %02X\n",i,dbgBuf[i]);
		}*/
	}

	void handleAllowed(uint8_t byte)
	{
		atomic UARTState = UART_BUSY;
		dbg(DBG_UART,"Byte out %02X, buflen=%d\n",byte,dbgBufCount);
		call comm.txByte(byte);
	}

	async command result_t UARTDebug.txByte(uint8_t byte)
	{
		bool tEnabled;
		bool doHandle=FALSE;
		#if defined(PLATFORM_PC) && !defined(NDEBUG)
		dbg(DBG_UART,"Byte in %02X, buflen=%d\n",byte,dbgBufCount);
		#endif
		//printBuf();
		atomic tEnabled=enabled;
		if (!tEnabled)
			return FAIL;
			
		atomic
		{
			if (UARTState == UART_IDLE)  // send byte if UART is idle
			{
				doHandle = TRUE;
				UARTState = UART_BUSY;
			}
		}
		if (doHandle)
			handleAllowed(byte);
		else {  // UART is busy, put byte into buffer
			// if buffer is full, the byte will be dropped
			bool killme= FALSE;
			atomic {
				if (dbgBufCount < DBG_BUF_LEN) {
					dbgBuf[dbgTail] = byte;
					ADVANCE(dbgTail);
					dbgBufCount++;
				}
				else // spit out a recognizable "panic" message
				{
					int i;
					enabled = FALSE;
					dbgBufCount-=4;
					for(i=0;i<4;i++)
						REDUCE(dbgTail);
					for(i=0;i<4;i++)
					{
						dbgBuf[dbgTail] = 0xFF;
						ADVANCE(dbgTail);
						dbgBufCount++;
					}
					killme = TRUE;
				}
			}
			if (killme)
				return FAIL;
		}
		return SUCCESS;
	}

	async event result_t comm.txByteReady(bool success) {return SUCCESS;}
	async event result_t comm.rxByteReady(uint8_t data, bool error, uint16_t strength) {return SUCCESS;}

	async event result_t comm.txDone()
	{
		// UART is able to send next byte
		uint8_t byte=0;
		bool doByte=FALSE;
		atomic
		{		
			if(dbgBufCount > 0) 
			{
				byte = dbgBuf[dbgHead];
				ADVANCE(dbgHead);
				dbgBufCount--;
				doByte = TRUE;
			} 
			else
			{
				UARTState = UART_IDLE;
				enabled = TRUE;
			}
		}
		if (doByte)
			handleAllowed(byte);
		return SUCCESS;
	}
}

