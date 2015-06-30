/* $Id: RandRW.nc,v 1.1 2005/07/11 23:27:38 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * @author David Gay
 */
/*
  address & 3:
  0, 2: r
  1: w
  3: r&w
*/
module RandRW {
  provides interface StdControl;
  uses {
    interface Leds;
    interface Mount;
    interface BlockRead;
    interface BlockWrite;
  }
}
implementation {
  enum {
    S_MOUNT,
    S_ERASE,
    S_WRITE,
    S_COMMIT,
    S_VERIFY,
    S_READ
  } state;

  enum {
    SIZE = 1024L * 256,
    NWRITES = SIZE / 4096
  };

  uint16_t shiftReg;
  uint16_t initSeed;
  uint16_t mask;

  /* Return the next 16 bit random number */
  uint16_t rand() {
    bool endbit;
    uint16_t tmpShiftReg;

    tmpShiftReg = shiftReg;
    endbit = ((tmpShiftReg & 0x8000) != 0);
    tmpShiftReg <<= 1;
    if (endbit) 
      tmpShiftReg ^= 0x100b;
    tmpShiftReg++;
    shiftReg = tmpShiftReg;
    tmpShiftReg = tmpShiftReg ^ mask;

    return tmpShiftReg;
  }

  void resetSeed() {
    shiftReg = 119 * 119 * ((TOS_LOCAL_ADDRESS >> 2) + 1);
    initSeed = shiftReg;
    mask = 137 * 29 * ((TOS_LOCAL_ADDRESS >> 2) + 1);
  }
  
  uint8_t data[512], rdata[512];
  int count;
  uint32_t addr, len;
  uint16_t offset;

  bool scheck(storage_result_t r) __attribute__((noinline)) {
    if (r != STORAGE_OK)
      call Leds.redOn();
    return r == STORAGE_OK;
  }

  bool rcheck(result_t r) {
    if (r != SUCCESS)
      call Leds.redOn();
    return r == SUCCESS;
  }

  void setParameters() {
    addr = (uint32_t)count << 12 | (rand() >> 6);
    len = rand() >> 7;
    if (addr + len > SIZE)
      addr = SIZE - len;
    offset = rand() >> 8;
    if (offset + len > sizeof data)
      offset = sizeof data - len;
  }

  command result_t StdControl.init() {
    int i;

    call Leds.init();
    resetSeed();
    for (i = 0; i < sizeof data; i++)
      data[i++] = rand() >> 8;

    return SUCCESS;
  }

  task void mount() {
    state = S_MOUNT;
    rcheck(call Mount.mount(1));
  }

  command result_t StdControl.start() {
    post mount();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void nextRead() {
    if (++count == NWRITES)
      {
	call Leds.greenOn();
      }
    else
      {
	setParameters();
	rcheck(call BlockRead.read(addr, rdata, len));
      }
  }

  void nextWrite() {
    if (++count == NWRITES)
      {
	call Leds.yellowToggle();
	state = S_COMMIT;
	rcheck(call BlockWrite.commit());
      }
    else
      {
	setParameters();
	rcheck(call BlockWrite.write(addr, data + offset, len));
      }
  }

  event void Mount.mountDone(storage_result_t result, volume_id_t id) {
    if (scheck(result))
      {
	if (TOS_LOCAL_ADDRESS & 1)
	  {
	    state = S_ERASE;
	    rcheck(call BlockWrite.erase());
	  }
	else
	  {
	    state = S_VERIFY;
	    rcheck(call BlockRead.verify());
	  }
      }
  }

  event void BlockWrite.writeDone(storage_result_t result, block_addr_t x, void* buf, block_addr_t y) {
    if (scheck(result))
      nextWrite();
  }

  event void BlockWrite.eraseDone(storage_result_t result) {
    if (scheck(result))
      {
	call Leds.yellowToggle();
	state = S_WRITE;
	count = 0;
	resetSeed();
	nextWrite();
      }
  }

  event void BlockWrite.commitDone(storage_result_t result) {
    if (scheck(result))
      {
	if (TOS_LOCAL_ADDRESS & 2)
	  {
	    call Leds.yellowToggle();
	    state = S_VERIFY;
	    rcheck(call BlockRead.verify());
	  }
	else
	  call Leds.greenOn();
      }
  }

  event void BlockRead.readDone(storage_result_t result, block_addr_t x, void* buf, block_addr_t rlen) __attribute__((noinline)) {
    if (scheck(result) && rcheck(x == addr && rlen == len && buf == rdata &&
				 memcmp(data + offset, rdata, rlen) == 0))
      nextRead();
  }

  event void BlockRead.verifyDone(storage_result_t result) {
    if (scheck(result))
      {
	call Leds.yellowToggle();
	state = S_READ;
	count = 0;
	resetSeed();
	nextRead();
      }
  }

  event void BlockRead.computeCrcDone(storage_result_t result, uint16_t z, block_addr_t x, block_addr_t y) {
  }
}
