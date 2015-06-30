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

module HPLSPIM {
	provides {
		interface FastSPI as SPI;
		interface StdControl;
	}
//	uses {
//		interface Leds;
//	}
}
implementation
{

	void wait();
	
	command result_t StdControl.init()
	{
//		call Leds.init();
		return SUCCESS;
	}
	
	command result_t StdControl.start()
	{
		PTED = 0x04;
		PTEPE = 0x00;
		PTEDD |= 0x34;
	
		// SPIC1
		// bit 7: SPI Interrupt Enable          (0)
		// bit 6: SPI System Enable             (1)
		// bit 5: SPI Transmit Interrupt Enable (0)
		// bit 4: Master/Slave Mode Select      (1 = Master)
		// bit 3: Clock Polarity                (0 = Active-high SPI clock)
		// bit 2: Clock Phase                   (0)
		// bit 1: Slave Select Output Enable    (0)
		// bit 0: LSB First                     (0 = MSB first)
		
		SPIC1 = 0x50; // Init SPI WAS:0x50

		// SPIC2
		// bit 7-5: Reserved/Unimplemented
		// bit 4:   Master Mode-Fault Function Enable (0)
		// bit 3:   Bidirectional Mode Output Enable  (0)
		// bit 2:   Reserved/Unimplemented
		// bit 1:   SPI Stop in Wait Mode             (0)
		// bit 0:   SPI Pin Control 0                 (0)

		SPIC2 = 0x00;
	
		// SPIBR
		// bit 7:   Reserved/Unimplemented
		// bit 6-4: SPI Baud Rate Prescale Divisor (1)
		// bit 3:   Reserved/Unimplemented
		// bit 2-0: SPI Baud Rate Divisor          (2)
		SPIBR = 0x00;
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		// SPIC1
		// bit 7: SPI Interrupt Enable          (0)
		// bit 6: SPI System Enable             (0)
		// bit 5: SPI Transmit Interrupt Enable (0)
		// bit 4: Master/Slave Mode Select      (0 = Slave)
		// bit 3: Clock Polarity                (0 = Active-high SPI clock)
		// bit 2: Clock Phase                   (0)
		// bit 1: Slave Select Output Enable    (0)
		// bit 0: LSB First                     (0 = MSB first)
	
		SPIC1 = 0x00;
		return SUCCESS;
	}
	
	inline async command void SPI.fastReadWord(uint8_t *data)
	{
		// This function runs in 61 bus clock cycles wasting 7.7 micro seconds.
		// Initialize SPI dummy transfer.
		asm("LDA 43");        // 3
		asm("MOV 45,45");     // 5
		
		// Wait for 19 instructions before data is ready.
		// SPI transfer time = 15 + 8*(250+15) = 2135 ns (4 MHz SPI clock assumed).
		wait();               // 13
		asm("BRN 0");         // 3
		asm("LDA 43");        // 3
		
		// Get result into variable "data", and initiate another dummy transfer.
		asm("STA 45");        // 3
		//asm("LDA 45");        // 3
		*data = SPID;
		
		// Wait another 16 instructions (we have 3 from LDA above) before data is ready.
		//asm("STA ,X");        // 2
		wait();               // 13
		asm("LDA 43");        // 3
		
		// Read data and return.
		//asm("LDA 45");        // 3
		//asm("STA 1,X");       // 3
		*(data+1) = SPID;
	}
	
	// Read a word over the SPI as LSB, MSB.
	inline async command void SPI.fastReadWordSwapped(uint8_t *data)
	{
		// This function runs in 61 bus clock cycles wasting 7.7 micro seconds.
		// This function should only be used for sequential burst transactions.
		//wait();
		//wait();
		// Initialize SPI dummy transfer.
		asm("LDA 43");        // 3
		asm("STA 45");        // 3
		
		// Wait for 19 instructions before data is ready.
		// SPI transfer time = 15 + 8*(250+15) = 2135 ns (4 MHz SPI clock assumed).
		wait();               // 13
		asm("BRN 0");         // 3
		asm("LDA 43");        // 3

		// Get result into variable "data", and initiate another dummy transfer.	
		asm("STA 45");        // 3
		//asm("LDA 45");        // 3
		
		// Wait another 19 instructions before data is ready.
		//asm("STA 1,X");       // 3
		*(data+1) = SPID;
		
		wait();               // 13
		//wait();
		asm("LDA 43");        // 3
		
		// Read data and return.
		//asm("LDA 45");        // 3
		//asm("STA ,X");        // 2
		*data = SPID;
		//wait();
	}
	
	inline async command void SPI.fastWriteWord(uint8_t *data)
	{
		// This function runs in 41 bus clock cycles wasting 5.1 micro seconds.
		// Write MSB
		asm("LDA 43");         // 3
		//asm("MOV X+,45");      // 5
		SPID = *data;
		// Wait until SPI write buffer empty
		asm("BRN 0");          // 3
		
		// Write LSB
		asm("LDA 43");         // 3
		//asm("MOV X+,45");      // 5
		SPID = *(data+1);
		
		// At this point, the first SPI write is 11 instructions underway,
		// needing 8 instructions to complete. The second SPI write then starts,
		// needing 19 instructions to complete giving a total of 27 instructions.

		// Wait for 13 instruction.
		wait();                // 13
		asm("LDA 43");         // 3
		wait();                // 13
	}

	inline async command void SPI.fastWriteWordSwapped(uint8_t *data)
	{
		// This function runs in 42 bus clock cycles wasting 5.3 micro seconds.

		// Write LSB
		asm("LDA 43");          // 3

		//while(!SPIS_SPTEF);
		SPID = *(data+1);
		// Wait until SPI write buffer empty
		asm("BRN 0");          // 3

		
		// Wait until SPI write buffer empty and write MSB
		//asm("BRN 0");             // 3
		//asm("DECX");            // 1
		//asm("DECX");            // 1
		
		//asm("MOV X+,45");       // 5
		//while(!SPIS_SPTEF);
		asm("LDA 43");          // 3
		SPID = *(data);
		//while (!SPIS_SPRF);
		
		// At this point, the first SPI write is 11 instructions underway,
		// needing 8 instructions to complete. The second SPI write then starts,
		// needing 19 instructions to complete giving a total of 27 instructions.

		// Wait for 13 instruction.
		wait();                // 13
		asm("LDA 43");         // 3
		wait();                // 13
	}

	inline async command void SPI.fastWriteByte(uint8_t data)
	{
		// This function runs in 25 bus clock cycles wasting 3.1 micro seconds.
		// Wait 6 cycles in case the function is inlined.
		// Write data to SPI
		asm("LDX 43");           // 3
		
		//while(!SPIS_SPTEF);
		SPID = data;
		//while (!SPIS_SPRF);
		
		// We have to wait 19 cycles in order for the SPI
		// transaction to be completed.

		// Wait for 13 instruction.
		wait();                // 13
		asm("BRN 0");          // 3
		asm("LDA 43");         // 3
		asm("LDA 45");

		//wait();                  // 13
		
		//asm("LDA 43");           // 3
		//asm("LDA 45");
		//asm("BRN 0");            // 3
	}
	
	async command uint8_t SPI.txByte(uint8_t data)
	{
		uint8_t temp_value;
		//temp_value = SPIS; // Clear status register (possible SPRF, SPTEF)
		temp_value = SPID; // Clear receive data register. SPI entirely ready for read or write
		while(!SPIS_SPTEF);
		//asm("bgnd");
		SPID = data;
		while (!SPIS_SPRF);
		asm("LDA 43");
		//call Leds.greenOn();
		//asm("bgnd");
		//while(1);
		return SPID;
	}
	
	// Helper function used to waste time :-)
	void wait() __attribute((noinline))
	{
		// Wait for 13 cycles (including jsr and rts).
		asm("NOP");        // 1
		asm("NOP");        // 1
	}
	
/*	TOSH_SIGNAL(SPI)
	{
		call Leds.redToggle();
		//asm("bgnd");
	}*/
}
