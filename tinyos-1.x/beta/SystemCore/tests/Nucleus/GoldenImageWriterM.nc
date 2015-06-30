// $Id: GoldenImageWriterM.nc,v 1.2 2004/09/06 21:51:25 gtolle Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * An application which clones the image programed into program flash
 * into external flash.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module GoldenImageWriterM {
  provides {
    interface StdControl;
  }
  uses {
    interface DelugeImgStableStore as StableStore;
    interface InternalFlash as IFlash;
    interface Leds;
    interface NetProg;
  }
}

implementation {

  enum {
    BUF_SIZE = 32,
  };

  uint8_t  buf[BUF_SIZE];
  uint16_t curBuf;
  bool     allDone;

  void fillBuf() {

    uint32_t target = 0, base, length;
    uint8_t  curBufPtr = 0;
    uint8_t  i;

    uint32_t offset = (uint32_t)curBuf * (uint32_t)BUF_SIZE;

    for ( i = 0; i < GIW_NUM_SECTIONS && curBufPtr < BUF_SIZE; i++ ) {
      base = startAddrs[i];
      length = endAddrs[i] - startAddrs[i];
      
      // base address
      for( ; offset < target + 4 && curBufPtr < BUF_SIZE; offset++ )
	buf[curBufPtr++] = (base >> ((offset-target)*8)) & 0xff;
      // length address
      for( target += 4; offset < target + 4 && curBufPtr < BUF_SIZE; offset++ )
	buf[curBufPtr++] = (length >> ((offset-target)*8)) & 0xff;
      // code data
      for( target += 4; offset < target + length && curBufPtr < BUF_SIZE; offset++ )
	buf[curBufPtr++] = GIW_GET_BYTE(base + (offset-target));

      target += length;
    }

    if (i >= GIW_NUM_SECTIONS) {
      for ( ; offset < target + 8 && curBufPtr < BUF_SIZE; offset++ )
	buf[curBufPtr++] = 0;
      if (offset >= target + 8)
	allDone = TRUE;
    }

  }

  task void writeData() {
    uint32_t offset = (uint32_t)curBuf * (uint32_t)BUF_SIZE;
    if (call StableStore.writeImgData(DELUGE_GOLDEN_IMAGE_NUM, offset, buf, BUF_SIZE) == FAIL)
      post writeData();
  }

  command result_t StdControl.init() { return SUCCESS; }
  
  command result_t StdControl.start() {
    
    uint8_t isGoldenImgLoaded;
    
    call IFlash.read((uint8_t*)BL_FLAGS_ADDR, &isGoldenImgLoaded, sizeof(isGoldenImgLoaded));

    // don't clone to flash if golden image has been loaded
    if (!(isGoldenImgLoaded & BL_GOLDEN_IMG_LOADED))
      return FAIL;
    
    // haven't cloned to flash before
    allDone = FALSE;
    curBuf = 0;

    // start cloning
    fillBuf();
    post writeData();

    return SUCCESS;

  }

  command result_t StdControl.stop() { return SUCCESS; }

  task void syncImgData() {
    if (call StableStore.syncImgData() == FAIL)
      post syncImgData();
  }

  event result_t StableStore.writeImgDataDone(result_t result) {

    if (result == FAIL) {
      // something went wrong, try again
      post writeData();
      return SUCCESS;
    }

    curBuf++;

    // if all done, sync image data
    if (allDone) {
      post syncImgData();
      return SUCCESS;
    }

    call Leds.set(curBuf);

    fillBuf();
    post writeData();

    return SUCCESS;

  }

  event result_t StableStore.syncImgDataDone(result_t result) { 

    uint16_t tmp16;
    uint8_t  tmp8;

    if (result == FAIL) {
      // something went wrong, try again
      post syncImgData();
      return SUCCESS;
    }

    // mark that golden image has been written
    call IFlash.read((uint8_t*)BL_FLAGS_ADDR, &tmp8, sizeof(tmp8));
    tmp8 &= ~BL_GOLDEN_IMG_LOADED;
    call IFlash.write((uint8_t*)BL_FLAGS_ADDR, &tmp8, sizeof(tmp8));

    // have bootloader reprogram chip to verify that everything is working
    tmp8 = BL_GESTURE_MAX_COUNT;
    call IFlash.write((uint8_t*)BL_GESTURE_COUNT_ADDR, &tmp8, sizeof(tmp8));
    tmp16 = BL_GOLDEN_IMG_ADDR;
    call IFlash.write((uint8_t*)(BL_NEW_IMG_START_PAGE_ADDR+0), &tmp16, sizeof(tmp16));

    call NetProg.reboot();

    return SUCCESS; 

  }

  event result_t StableStore.checkCrcDone(result_t result) { return SUCCESS; }
  event result_t StableStore.getImgDataDone(result_t result) { return SUCCESS; }

}
