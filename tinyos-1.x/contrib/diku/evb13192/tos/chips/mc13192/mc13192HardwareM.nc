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

module mc13192HardwareM {
	provides {
		interface mc13192Regs as Regs;
	}
	uses interface FastSPI as SPI;
}
implementation
{
	// Forward declarations
	void disable_MC13192_interrupts();
	void restore_MC13192_interrupts();
	void wait();

	uint8_t irq_value = 0;

	async command uint16_t Regs.read(uint8_t addr)
	{
		uint16_t w=0; // w[0] is MSB, w[1] is LSB
		// Do read if SPI is free.
//		if (MC13192_CE) {
		if (TOSH_READ_RADIO_CE_PIN()) {
			disable_MC13192_interrupts(); // Necessary to prevent double SPI access
			//ASSERT_CE; // Enables MC13192 SPI
			TOSH_CLR_RADIO_CE_PIN();
			//call SPI.txByte((addr & 0x3f) | 0x80); // Mask address, 6bit addr, Set read bit.
			call SPI.fastWriteByte((addr & 0x3f) | 0x80);
			//((uint8_t*)&w)[0] = call SPI.txByte(0); // MSB
			//((uint8_t*)&w)[1] = call SPI.txByte(0); // LSB
			call SPI.fastReadWord((uint8_t*)&w);
			//DEASSERT_CE; // Disables MC13192 SPI
			TOSH_SET_RADIO_CE_PIN();
			restore_MC13192_interrupts(); // Restore MC13192 interrupt status
		}
		return w;
	}
	
	async command result_t Regs.write(uint8_t addr, uint16_t content)
	{
		// Do write if SPI is free.
		//if (!MC13192_CE) {
/*		if (!TOSH_READ_RADIO_CE_PIN()) {
			call ConsoleOut.print("SPI Busy while trying to write!\n");
		}*/
			disable_MC13192_interrupts(); // Necessary to prevent double SPI access
			TOSH_CLR_RADIO_CE_PIN();
			//ASSERT_CE; // Enables MC13192 SPI
			call SPI.fastWriteByte(addr & 0x3F);
			call SPI.fastWriteWord((uint8_t*)&content);
			//DEASSERT_CE; // Disables MC13192 SPI
			TOSH_SET_RADIO_CE_PIN();
			restore_MC13192_interrupts(); // Restore MC13192 interrupt status
			return SUCCESS;
		//}
		//return FAIL;
	}
	
	inline async command result_t Regs.seqReadStart(uint8_t addr)
	{
		//disable_MC13192_interrupts(); // Necessary to prevent double SPI access
		//ASSERT_CE; // Enables MC13192 SPI
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte((addr & 0x3f) | 0x80);
		return SUCCESS;
	}
	
	inline async command result_t Regs.seqEnd()
	{
		wait();
		wait();
		//DEASSERT_CE; // Disables MC13192 SPI
		TOSH_SET_RADIO_CE_PIN();
		//restore_MC13192_interrupts(); // Restore MC13192 interrupt status
		return SUCCESS;
	}
	
	inline async command result_t Regs.seqReadWord(uint8_t *buffer)
	{
		call SPI.fastReadWordSwapped(buffer);
		return SUCCESS;
	}
	
	inline async command result_t Regs.seqWriteStart(uint8_t addr)
	{
		//disable_MC13192_interrupts(); // Necessary to prevent double SPI access
		//ASSERT_CE; // Enables MC13192 SPI
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(addr & 0x3F);
		return SUCCESS;
	}
	
	inline async command result_t Regs.seqWriteWord(uint8_t *buffer)
	{
		call SPI.fastWriteWordSwapped(buffer);
		return SUCCESS;
	}
	
	// Helper functions below here.	
	void disable_MC13192_interrupts()
	{
		atomic {
			irq_value = MC13192_IRQ_SOURCE;
			DISABLE_IRQ;
		}
	}

	void restore_MC13192_interrupts()
	{
		atomic {
			MC13192_IRQ_SOURCE = irq_value;
		}
	}

	// Helper function used to waste time :-)
	void wait() __attribute((noinline))
	{
		// Wait for 13 cycles (including jsr and rts).
		asm("NOP");        // 1
		asm("NOP");        // 1
	}
}
