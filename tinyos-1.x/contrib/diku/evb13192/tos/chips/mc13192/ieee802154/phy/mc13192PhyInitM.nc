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

#include "macConstants.h"
#include "endianconv.h"
module mc13192PhyInitM {
	provides
	{
		interface StdControl;
		interface PhyReset;
	}
	uses
	{
		interface LocalTime as MCUTime;
		interface mc13192PhyTimer as RadioTime;
		interface FastSPI as SPI;
		interface Debug;
	}
}
implementation
{
	#include <mc13192Registers.h>

	#define DBG_LEVEL 1
	#include "Debug.h"

	void initialize()
	{
		// Enable interrupts.
		ENABLE_IRQ;
		
		// Time to setup the radio registers.
		// Please refer to document MC13192RM for hidden register initialization
		// Register 0x11 is hidden. bit 8-9 should be initialized to 00.
		writeRegister(0x11,0xA0FF);
		
		writeRegister(GPIO_DIR, 0x3F80);
		writeRegister(CCA_THRESH,0x9674); // WAS: 0xA08D
		// Register 0x08 is hidden. bit 1 and 4 should be initialized to 1.
		// Preferred injection
		writeRegister(0x08,0xFFF7);
		
		 // ATTN masks, LO1
		writeRegister(IRQ_MASK,0x8240);

		// Register 0x06 has some hidden bits. bit 14 should be initialized to 1.
		writeRegister(CONTROL_A,0x4010);
 
 		// Secret register settings snatched from Freescale implementation
 		writeRegister(0x13, 0x1843);
 		writeRegister(0x31, 0xA000);
 		writeRegister(0x38, 0x0008);
 		
 		// These should fix excess power consumption during hibernate and doze.
 		writeRegister(CONTROL_B, 0x7D00); // Was: 0x7D1C (xx00)
 		
 		// Timer prescale = 5
 		// Enable alt_GPIO
 		// Enable clock output.
 		writeRegister(CONTROL_C, 0xF3FD); // Was: 0xF3FA (xxxD)
 		
 		// Use Freescale xtal trim value.
 		// clock rate = 5 (62.5 KHz)
 		writeRegister(CLKO_CTL, 0x3645);
 		
 		// Sets the reset indicator bit
		readRegister(RST_IND);
		// Read the status register to clear any undesired IRQs.
		readRegister(IRQ_STATUS);
		//call State.setRXTXStateMirror(IDLE_MODE);
	}

	command void PhyReset.reset()
	{
		// Synchronize radio and MCU time.
		call RadioTime.resetEventTime();
		call MCUTime.reset();
	}

	command result_t StdControl.init()
	{
		// Initialize GPIO pins.
		TOSH_SET_RADIO_CE_PIN();
		TOSH_SET_RADIO_ATTN_PIN();
		TOSH_CLR_RADIO_RXTXEN_PIN();
		TOSH_CLR_RADIO_RESET_PIN();
		TOSH_CLR_RADIO_ANT_CTRL_PIN();
		TOSH_CLR_RADIO_LNA_CTRL_PIN();

		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		uint16_t irq_reg, attn_irq = FALSE;

		// We then power up the radio and wait for it to init.
		ACK_IRQ;
		SETUP_IRQ_PIN;
		// Detect IRQ on both level and edge to prevent fast double IRQ bug.
		IRQ_LEVEL_EDGE;
		
		// Take MC13192 out of reset
		TOSH_SET_RADIO_RESET_PIN();
		
		while (attn_irq == FALSE) {
			// Check to see if IRQ is asserted
			if (IRQ_FLAG_SET) {
				// Clear MC13192 interrupts and check for ATTN IRQ from 13192.
				irq_reg = readRegister(IRQ_STATUS);
				irq_reg &= 0x400;
				if (irq_reg != 0) attn_irq = TRUE;
				// ACK the pending interrupt.
				ACK_IRQ;
			}
		}
		
		initialize();
		
		// Use external clock.
		extClock = 62500;
		enterFEEMode(0,8,1); // FLL engaged, 32 MHz MCUclk / 16 MHz BUSclk.
		
		// Set MAC address
		// TODO: This should be done in a nicer way!
		radioMACAddr = (uint8_t*)MAC_ADDR_LOCATION;
		NTOUH64(radioMACAddr, aExtendedAddress);
		
		// Synchronize radio and MCU time.
		call RadioTime.resetEventTime();
		call MCUTime.reset();
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		//ASSERT_RESET; // Power off the radio.
		TOSH_CLR_RADIO_RESET_PIN();
		return SUCCESS;
	}
}
