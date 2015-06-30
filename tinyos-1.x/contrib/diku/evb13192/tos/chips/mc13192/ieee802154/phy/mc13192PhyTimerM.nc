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

module mc13192PhyTimerM
{
	provides {
		interface mc13192PhyTimer as Timer;
		interface StdControl;
	}
	uses {
		interface FastSPI as SPI;
		interface Debug;
	}
}
implementation
{
	#include <mc13192Registers.h>

	#define DBG_LEVEL 1
	#include "Debug.h"

	// Global variables.
	bool eventTimerSet = FALSE;

	command result_t StdControl.init()
	{
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		// Stop all timers.
		call Timer.stopAckTimer();
		call Timer.stopEventTimer();
		call Timer.stopDeferTimer1();
		call Timer.stopDeferTimer2();
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		// Stop all timers.
		call Timer.stopAckTimer();
		call Timer.stopEventTimer();
		call Timer.stopDeferTimer1();
		call Timer.stopDeferTimer2();
		return SUCCESS;
	}

	/******************************/
	/* Event triggering functions */
	/******************************/

	command bool Timer.eventTimerIsSet()
	{
		return eventTimerSet;
	}

	async command void Timer.startAckTimer(uint32_t timeout)
	{
		uint16_t mask;
		// Turn Timer1 mask on
		writeRegister(TMR_CMP1_A, (uint16_t)(timeout >> 16));
		writeRegister(TMR_CMP1_B, (uint16_t)timeout);
		
		// enable timer interrupt.
		mask = readRegister(IRQ_MASK);
		mask |= TIMER1_IRQMASK_BIT;
		writeRegister(IRQ_MASK, mask);
	}
	
	async command void Timer.stopAckTimer()
	{
		uint16_t mask;
		// disable timer interrupt.
		mask = readRegister(IRQ_MASK);
		mask &= ~(TIMER1_IRQMASK_BIT);
		writeRegister(IRQ_MASK, mask);
		
		// Disable timer compare.
		writeRegister(TMR_CMP1_A, 0x8000);
	}

	async command void Timer.startEventTimer(uint32_t commenceTime, uint8_t mode)
	{
		uint16_t reg, mask;

		// enable timer interrupt.
		mask = readRegister(IRQ_MASK);
		mask |= TIMER2_IRQMASK_BIT;
		writeRegister(IRQ_MASK, mask);
		eventTimerSet = TRUE;
		
		// Program the right register with the timeout.
		if (mode == STREAM_MODE) {
			// Write timeout to tc2_prime
			writeRegister(TC2_PRIME, (uint16_t)commenceTime);
			// Write to tmr_cmp2_dis
			writeRegister(TMR_CMP2_A, 0x0000);
		} else {
			// Assume packet mode.
			// Write timeout to tmr_cmp2
			writeRegister(TMR_CMP2_A, (uint16_t)(commenceTime >> 16));
			writeRegister(TMR_CMP2_B, (uint16_t)commenceTime);
		}
	}
	
	async command void Timer.stopEventTimer()
	{
		uint16_t mask;
		// disable timer interrupt.
		mask = readRegister(IRQ_MASK);
		mask &= ~(TIMER2_IRQMASK_BIT);
		writeRegister(IRQ_MASK, mask);
		
		// Disable timer compare.
		writeRegister(TMR_CMP2_A, 0x8000);
		eventTimerSet = FALSE;
	}

	async command void Timer.startDeferTimer1(uint32_t timeout)
	{
		uint16_t mask;
		// Turn Timer1 mask on
		writeRegister(TMR_CMP3_A, (uint16_t)(timeout >> 16));
		writeRegister(TMR_CMP3_B, (uint16_t)timeout);
		
		// enable timer interrupt.
		mask = readRegister(IRQ_MASK);
		mask |= TIMER3_IRQMASK_BIT;
		writeRegister(IRQ_MASK, mask);
	}
	
	async command void Timer.stopDeferTimer1()
	{
		uint16_t mask;
		// disable timer interrupt.
		mask = readRegister(IRQ_MASK);
		mask &= ~(TIMER3_IRQMASK_BIT);
		writeRegister(IRQ_MASK, mask);
		
		// Disable timer compare.
		writeRegister(TMR_CMP3_A, 0x8000);
	}

	async command void Timer.startDeferTimer2(uint32_t timeout)
	{
		uint16_t mask;
		// Turn Timer1 mask on
		writeRegister(TMR_CMP4_A, (uint16_t)(timeout >> 16));
		writeRegister(TMR_CMP4_B, (uint16_t)timeout);
		
		// enable timer interrupt.
		mask = readRegister(IRQ_MASK);
		mask |= TIMER4_IRQMASK_BIT;
		writeRegister(IRQ_MASK, mask);
	}

	async command void Timer.stopDeferTimer2()
	{
		uint16_t mask;
		// disable timer interrupt.
		mask = readRegister(IRQ_MASK);
		mask &= ~(TIMER4_IRQMASK_BIT);
		writeRegister(IRQ_MASK, mask);
		
		// Disable timer compare.
		writeRegister(TMR_CMP4_A, 0x8000);
	}
	
	command uint32_t Timer.getEventTime()
	{
		uint8_t timestamp[4];

		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(CURRENT_TIME_A|0x80);
		call SPI.fastReadWord(timestamp);
		call SPI.fastReadWord(timestamp+2);
		TOSH_SET_RADIO_CE_PIN();

		return *(uint32_t*)timestamp;
	}
	
	command void Timer.resetEventTime()
	{
		uint8_t timestamp[2] = {0x00, 0x00};
		// Program Time1 comparator with time.
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(TMR_CMP1_A);
		call SPI.fastWriteWord(timestamp);
		call SPI.fastWriteWord(timestamp);
		TOSH_SET_RADIO_CE_PIN();
		
		writeRegister(CONTROL_B, STREAM_MODE_OFF|0x8000);
	}
}
