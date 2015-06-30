/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

module mc13192PhyInterruptM {
	provides
	{
		interface mc13192PhyInterrupt as Interrupt;
	}
	uses
	{
		interface FastSPI as SPI;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	// Forward declarations.
	inline void handleAttnIRQ();
	
	// No race conditions, since variable is
	// read/written in one instruction.
	norace bool fastAction = FALSE;
	norace bool streamMode = FALSE;

	async command void Interrupt.enableStreamMode()
	{
		atomic streamMode = TRUE;
	}
	
	async command void Interrupt.disableStreamMode()
	{
		atomic streamMode = FALSE;
	}
	
	async command void Interrupt.disableFastAction()
	{
		 fastAction = FALSE;
	}

	// MC13192 interrupt handler.
	TOSH_SIGNAL(IRQ)
	{
		volatile uint16_t status_content; // Result of the status register read.

		DISABLE_IRQ;		
		ACK_IRQ; // Acknowledge the interrupt. MC13192 IRQ pin still low.

		if (fastAction) {
			// The fastAction event disables fastaction
			// when done receiving/transmitting.
			fastAction = signal Interrupt.fastAction();
			
			// Now check if our fast action made the IRQ pin go high again.
			// If not, the interrupt was more than just an ordinary stream
			// rx/tx interrupt.
			if (!IRQ_FLAG_SET) {
				// Just enable interrupts and get out!
				ENABLE_IRQ;
				return;
			}
			
			ACK_IRQ;
			// It takes 133 bus cycles to read the IRQ status register.
			//ASSERT_CE;
			TOSH_CLR_RADIO_CE_PIN();
			call SPI.fastWriteByte(IRQ_STATUS|0x80);
			call SPI.fastReadWord((uint8_t*)&status_content);
			//DEASSERT_CE;
			TOSH_SET_RADIO_CE_PIN();

			// It takes 335 bus cycles to process a read interrupt = 42 micro seconds
			// It takes 327 bus cycles to process a write interrupt = 41 micro seconds

			if ((status_content & 0xF100)) {
				// Receive operation timeout handling.
				if (status_content & TIMER1_IRQ_MASK) 
				{
					signal Interrupt.ackTimerFired();
				}

				// LO LOCK IRQ - Occurs when MC13192 loses channel frequency lock.
				// When this happens, all rx/tx traffic is aborted.
				if (status_content & LO_LOCK_IRQ_MASK)
				{
					signal Interrupt.lockLost();
				}
			
				if (status_content & STRM_DATA_ERR_IRQ_MASK) {
					DBG_STR("Stream error bit was set!",2);
				}
			}
			ENABLE_IRQ;
			return;
		}
		
		// It takes 133 bus cycles to read the IRQ status register.
		//ASSERT_CE;
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(IRQ_STATUS|0x80);
		call SPI.fastReadWord((uint8_t*)&status_content);
		//DEASSERT_CE;
		TOSH_SET_RADIO_CE_PIN();
		//DBG_STRINT("Status was:",status_content,1);
		// If packet RX is done
		// In stream mode this is time critical.. This needs to be first.
		// Stream RX takes 17 + 133 + 45 + 275 = 470 bus cycles = 58,75 micro seconds.
		if (status_content & RX_IRQ_MASK) {
			//if (streamMode) {
				// 275 bus cycles to prepare stream read.
				fastAction = signal Interrupt.streamRead();
			/*} else {
				signal Interrupt.dataIndication(status_content & CRC_VALID_MASK);
			}*/
			ENABLE_IRQ;
			return;
		}

		// If packet TX done signal senddone.
		// In stream mode this is time critical.. This needs to be first.
		// Stream TX takes 17 + 133 + 50 + 173 = 373 bus cycles = 46,6 micro seconds.
		if (status_content & TX_IRQ_MASK) {
			if (streamMode) {
				// This takes 173 bus cycles to complete.
				fastAction = signal Interrupt.fastAction();
			} else {
				signal Interrupt.txDone();
			}
			ENABLE_IRQ;
			return;
		}

		if (!(status_content & 0xFFFC)) {
			ENABLE_IRQ;
			return;
		}

		// TIMER1 IRQ Handler
		if (status_content & TIMER1_IRQ_MASK) 
		{
			signal Interrupt.ackTimerFired();
		}

		// LO LOCK IRQ - Occurs when MC13192 loses channel frequency lock.
		// When this happens, all rx/tx traffic is aborted.
		if (status_content & LO_LOCK_IRQ_MASK)
		{
			signal Interrupt.lockLost();
		}

		// DOZE Complete Interrupt
/*		if (status_content & DOZE_IRQ_MASK)
		{
			signal Control.dozeIndication();
		}
		
		// ATTN IRQ Handler
		if (status_content & ATTN_IRQ_MASK)
		{
			handleAttnIRQ();
		}*/
				
		// TIMER2 IRQ Handler
		if (status_content & TIMER2_IRQ_MASK) 
		{
			signal Interrupt.eventTimerFired();
		}		
		
		// TIMER3 IRQ Handler
		if (status_content & TIMER3_IRQ_MASK) 
		{
			signal Interrupt.deferTimer1Fired();
		}		

		// TIMER4 IRQ Handler
		if (status_content & TIMER4_IRQ_MASK)
		{
			signal Interrupt.deferTimer2Fired();
		}
		
		// If CCA done signal
		if (status_content & CCA_IRQ_MASK) {
			signal Interrupt.ccaDone(!(status_content & CCA_STATUS_MASK));
		}

		// Dunno what this IRQ is. Snatched from Freescale code.
/*		if (status_content & HG_IRQ_MASK) {
			uint16_t reg,i;
			//for (i=0x00;i<0x40;i++) {
			TOSH_CLR_RADIO_CE_PIN();
			call SPI.fastWriteByte(0x2A|0x80);
			call SPI.fastReadWord((uint8_t*)&reg);
			TOSH_SET_RADIO_CE_PIN();
			DBG_STRINT("Register 0x2A:",reg,1);
			//}
			DBG_STR("Got HG irq!",1);
		}*/

		// Unhandled IRQ!
/*		DBG_STR("Unhandled IRQ!!!",3);
		DBG_STR("status_content is:",3);
		DBG_INT(status_content,3);*/
		
		ENABLE_IRQ;
	}
		
/*	inline void handleAttnIRQ()
	{
		uint16_t tmp;

		// Read the MC13192 reset indicator register.
		//ASSERT_CE;
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(RST_IND|0x80);
		call SPI.fastReadWord((uint8_t*)&tmp);
		//DEASSERT_CE;
		TOSH_SET_RADIO_CE_PIN();
		tmp &= RESET_BIT_MASK;
		if (tmp == 0) {
			// If RST_IND is 0, a reset has occured.
			signal Control.resetIndication();
		} else {
			// This must be a wakeup request.
			signal Control.wakeUpIndication();
		}	
	}*/
	
	// Default events.
/*	default async event void Control.resetIndication() {}
	default async event void Control.wakeUpIndication() {}
	default async event void Control.dozeIndication() {}*/
	
}
