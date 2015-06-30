/* Copyright (c) 2006, Marcus Chang, Jan Flora
   All rights reserved.

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer. 

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution. 

    * Neither the name of the Dept. of Computer Science, University of 
      Copenhagen nor the names of its contributors may be used to endorse or 
      promote products derived from this software without specific prior 
      written permission. 

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
   POSSIBILITY OF SUCH DAMAGE.
*/  

/*
	Author:		Marcus Chang <marcus@diku.dk>
				Jan Flora <j@nflora.dk>
	Last modified:	June, 2006
*/

#include "mc13192Const.h"
#include "mcuToRadioPorts.h"


module RadioClockControlM 
{
	uses {
		interface mc13192Regs as Regs;
		interface mc13192State as State;
		interface StdControl as SPIControl;
	}

	provides interface ExternalClockControl as ECG;

}

implementation
{

	void setupExternalClock();
	result_t setClockRate(uint8_t freq);

	bool clockLost = FALSE;
	
	command result_t ECG.init() {

		uint16_t irq_reg, attn_irq = FALSE;

		call SPIControl.init();
		call SPIControl.start();
		
		call State.setRXTXStateMirror(INIT_MODE);

		// Initialize GPIO pins.
		TOSH_SET_RADIO_CE_PIN();
		TOSH_SET_RADIO_ATTN_PIN();
		TOSH_CLR_RADIO_RXTXEN_PIN();
		TOSH_CLR_RADIO_RESET_PIN();
		TOSH_CLR_RADIO_ANT_CTRL_PIN();
		TOSH_CLR_RADIO_LNA_CTRL_PIN();
	

		// We then power up the radio and wait for it to init.
		ACK_IRQ;
		SETUP_IRQ_PIN;
		// Detect IRQ on both level and edge to prevent fast double IRQ bug.
		IRQ_LEVEL_EDGE;
		
		//DEASSERT_RESET; // Take MC13192 out of reset
		TOSH_SET_RADIO_RESET_PIN();
		
		while (attn_irq == FALSE) {
			if (IRQ_FLAG_SET) { // Check to see if IRQ is asserted
				// Clear MC13192 interrupts and check for ATTN IRQ from 13192.
				irq_reg = call Regs.read(IRQ_STATUS);
				irq_reg &= 0x400;
				if (irq_reg != 0)
					attn_irq = TRUE;
				ACK_IRQ; // ACK the pending IRQ interrupt.
			}
		}
		
		ENABLE_IRQ; // Enable interrupts.

		// Time to setup the radio.
		// Please refer to document MC13192RM for hidden register initialization
		// Register 0x11 is hidden. bit 8-9 should be initialized to 00.
		call Regs.write(0x11,0xA0FF);
		call Regs.write(GPIO_DIR, 0x3F80);
		call Regs.write(CCA_THRESH,0x9674); // WAS: 0xA08D
		// Register 0x08 is hidden. bit 1 and 4 should be initialized to 1.
		// Preferred injection
		call Regs.write(0x08,0xFFF7);
		 // ATTN masks, LO1
		call Regs.write(IRQ_MASK,0x8240);
		// Register 0x06 has some hidden bits. bit 14 should be initialized to 1.
		call Regs.write(CONTROL_A,0x4010);
 
 		// Secret register settings snatched from Freescale implementation
 		call Regs.write(0x13, 0x1843);
 		call Regs.write(0x31, 0xA000);
 		call Regs.write(0x38, 0x0008);
 		
 		// These should fix excess power consumption during hibernate and doze.
 		call Regs.write(CONTROL_B, 0x7D00); // Was: 0x7D1C (xx00)
 		call Regs.write(CONTROL_C, 0xF3FA); // Was: 0xF3FA (xxxD)
 		
 		call Regs.write(CLKO_CTL, 0x3645); // Use Freescale xtal trim value.
 		
 		// Sets the reset indicator bit
		call Regs.read(RST_IND);
		// Read the status register to clear any undesired IRQs.
		call Regs.read(IRQ_STATUS);
		call State.setRXTXStateMirror(IDLE_MODE);
		
		return SUCCESS;
	}

	//////////////////////////////////////////////////////////////////////////
	// clko_rate 	CLKO
	// 000		16 MHz
	// 001 		8 MHz
	// 010 		4 MHz
	// 011	 	2 MHz
	// 100 		1 MHz
	// 101 		62.5 kHz
	// 110 		(default) 32.786+ kHz = 16 MHz / 488
	// 111 		16.393+ kHz = 16 MHz / 976
	//////////////////////////////////////////////////////////////////////////
	command result_t ECG.setClockRate(uint8_t freq)
	{
		uint16_t clockCtl;

		uint32_t table[8];
		table[0] = 16000000;
		table[1] = 8000000;
		table[2] = 4000000;
		table[3] = 2000000;
		table[4] = 1000000;
		table[5] = 62500;
		table[6] = 32786;
		table[7] = 16393;

		extClock = table[freq];

		clockCtl = call Regs.read(CLKO_CTL); // Read register and re-write
		clockCtl &= 0xFFF8;
		clockCtl |= (freq & 0x07); // only 3 bits.
		call Regs.write(CLKO_CTL, clockCtl);

		return SUCCESS;
	}


	// Loss of clock interrupt handler.
	TOSH_SIGNAL(ICG) {
		ICGS1 |= 0x01; /* Clear lost clock interrupt */
		clockLost = TRUE;
		//call Leds.redToggle();
	}
}
