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

interface mc13192Regs
{
	/**
	 * Read data from MC13192 register. 
	 *
	 * <p>This command is asynchronous, but may fail. Make sure to check the 
	 * return code.</p>
	 *
	 * @param addr Register to read from.
	 * @return Value read from register.
	 */
	async command uint16_t read(uint8_t addr);

	/**
	 * Write data to MC13192 register. 
	 *
	 * <p>This command is asynchronous, but may fail. Make sure to check the 
	 * return code.</p>
	 *
	 * @param addr Address to write to.
	 * @param content The value to write
	 * @return SUCCESS/FAIL.
	 */
	async command result_t write(uint8_t addr, uint16_t content);
	
	async command result_t seqWriteStart(uint8_t addr);
	async command result_t seqReadStart(uint8_t addr);
	async command result_t seqEnd();
	async command result_t seqWriteWord(uint8_t *buffer);
	async command result_t seqReadWord(uint8_t *buffer);
}
