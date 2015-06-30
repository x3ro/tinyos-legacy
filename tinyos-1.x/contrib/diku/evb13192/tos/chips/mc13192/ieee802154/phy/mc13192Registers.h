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
// This file assumes that the SPI interface has been "used" before including.

#ifndef _MC13192REGISTER_H_
#define _MC13192REGISTER_H_
	
	// inlined versions.
	inline void writeRegisterFast(uint8_t addr, uint16_t content)
	{
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(addr);
		call SPI.fastWriteWord((uint8_t*)&content);
		TOSH_SET_RADIO_CE_PIN();
	}
	
	inline uint16_t readRegisterFast(uint8_t addr)
	{
		uint16_t w=0;
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(addr | 0x80);
		call SPI.fastReadWord((uint8_t*)&w);
		TOSH_SET_RADIO_CE_PIN();
		return w;
	}

	// Functions not inlined
	void writeRegister(uint8_t addr, uint16_t content) __attribute((noinline))
	{
		writeRegisterFast(addr, content);
	}

	uint16_t readRegister(uint8_t addr) __attribute((noinline))
	{
		return readRegisterFast(addr);
	}

#endif
