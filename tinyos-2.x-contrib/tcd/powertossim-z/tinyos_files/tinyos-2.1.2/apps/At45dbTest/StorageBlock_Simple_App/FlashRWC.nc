/*
 * Copyright (c) 2008 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Reads and writes from the flash periodically.  Based on the implementation
 * of Block storage test application by David Gay at:
 * /apps/tests/storage/Block/RandRWC.nc
 *
 * @author Ricardo Simon Carbajo
 */

module FlashRWC {
  uses {
    interface Boot;
    interface Leds;
    interface BlockRead;
    interface BlockWrite;
    
	interface Timer<TMilli> as MilliTimerWrite;
	interface Timer<TMilli> as MilliTimerRead;
  }
}
implementation {
  enum {
    SIZE_FLASH = 1024L * 256,
	SIZE_BUFFER = 512,
    NWRITES = 511,
  };  
  enum {
    A_WRITE = 0, 
	A_READ = 1
  };

  uint8_t data[SIZE_BUFFER], rdata[SIZE_BUFFER];
  int count, testCount;
  uint32_t addr, len;
  uint16_t offset;
  void done();
  void setParameters();
	

  void setParameters() {
	addr = (uint32_t)count << 9;
	len =512;  
	offset=0;
  }
  
  void nextWrite() {
    if (++count == NWRITES + 1)
	{
		call Leds.led2Toggle();
		call BlockWrite.sync();
    }
    else
    {
		setParameters();
		call Leds.led2Toggle();
		call BlockWrite.write(addr, data + offset, len);
    }
  }
  
  void nextRead() {
    if (++count == NWRITES + 1)
		done();
    else
    {
		setParameters();
		call Leds.led0Toggle();
		call BlockRead.read(addr, rdata, len);
    }
  }
  
  void doAction(int act) {
    count = 0;
    
	if (act == A_WRITE){
		call BlockWrite.erase();
	}
	
	if (act == A_READ){
		nextRead();
	}
  }


  void done() {

    call Leds.led0Toggle();

    if (testCount == 0){
	  doAction(A_WRITE);
	  testCount++;
	}
	else if (testCount == 1){
	  doAction(A_READ);
	  testCount++;
	}
	
  }

  //////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////
  //INTERFACES
  //////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////
  
  event void Boot.booted() {
	uint16_t i;
    count =0 ;
	testCount = 0;
	
    for (i = 0; i < SIZE_BUFFER; i++)
      data[i++] = rand() >> 8;

	setParameters();
    done();
  }

  event void BlockWrite.writeDone(storage_addr_t x, void* buf, storage_len_t y, error_t result) {
    
    if (result == SUCCESS){
	  call MilliTimerWrite.startOneShot(1000);
	}
  }

  event void BlockWrite.eraseDone(error_t result) {
    
	if (result == SUCCESS)
    {
		nextWrite();
    }
  }

  event void BlockWrite.syncDone(error_t result) {
  
	if (result == SUCCESS)
      done();
  }

  event void BlockRead.readDone(storage_addr_t x, void* buf, storage_len_t rlen, error_t result) __attribute__((noinline)) {
    
	if ((result == SUCCESS) && (x == addr && rlen == len && buf == rdata &&
				 (memcmp(data + offset, rdata, rlen) == 0))){
		call MilliTimerRead.startOneShot(1000);
	}
  }

  event void BlockRead.computeCrcDone(storage_addr_t x, storage_len_t y, uint16_t z, error_t result) {
  }

  
  event void MilliTimerWrite.fired() {
	nextWrite();
  }
  event void MilliTimerRead.fired() {
	nextRead();
  }
  

}
