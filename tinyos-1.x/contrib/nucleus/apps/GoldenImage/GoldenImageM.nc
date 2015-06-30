// $Id: GoldenImageM.nc,v 1.1 2005/04/15 00:00:41 gtolle Exp $

/*									tab:4
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
 */

/*
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module GoldenImageM {
  provides {
    interface StdControl;
  }
  uses {
    interface DelugeDataWrite as DataWrite;
    interface DelugeMetadata as Metadata;
    interface DelugeStorage as Storage;
    interface FlashWP;
    interface InternalFlash as IFlash;
    interface Leds;
    interface NetProg;
    interface SplitControl as MetadataControl;
    interface StdControl as DelugeControl;
    interface StdControl as MgmtQueryControl;
  }
}

implementation {

typedef struct {
  uint32_t unix_time;  //the unix time that the program was compiled
  uint32_t user_hash;  //a hash of the username and hostname that did the compile
  char user_id[IDENT_MAX_PROGRAM_NAME_LENGTH]; // username that did the compile
  char hostname[IDENT_MAX_PROGRAM_NAME_LENGTH]; // hostname that did the compile
  char program_name[IDENT_MAX_PROGRAM_NAME_LENGTH];  //name of the installed program
} ImageInfo_t;

static const ImageInfo_t imageInfo = {
  unix_time : IDENT_UNIX_TIME,
  user_hash : IDENT_USER_HASH,
  user_id : { IDENT_USER_ID_BYTES },
  hostname : { IDENT_HOSTNAME_BYTES },
  program_name : { IDENT_PROGRAM_NAME_BYTES },
};

  enum {
    BUF_SIZE = 128,
  };

  uint8_t  buf[BUF_SIZE];
  uint16_t curBuf;
  bool     allDone;

  DelugeImgDesc imgDesc;

  void fillBuf() {

    uint32_t target = 0, base, length;
    uint8_t  curBufPtr = 0;
    uint8_t  i;

    uint32_t offset = (uint32_t)(curBuf-1) * (uint32_t)BUF_SIZE;

    if (curBuf == 0) {
      for ( i = 0; i < BUF_SIZE; i++ )
	buf[i] = 0;

      // program name
      memcpy(&buf[target], imageInfo.program_name, 16);
      target += 16;
      // user id
      memcpy(&buf[target], imageInfo.user_id, 16);
      target += 16;
      // hostname
      memcpy(&buf[target], imageInfo.hostname, 16);
      target += 16;
      // compile time
      memcpy(&buf[target], &imageInfo.unix_time, sizeof(imageInfo.unix_time));
      target += sizeof(imageInfo.unix_time);
      // user hash
      memcpy(&buf[target], &imageInfo.user_hash, sizeof(imageInfo.user_hash));
      target += sizeof(imageInfo.user_hash);
      return;
    }

    for ( i = 0; i < GI_NUM_SECTIONS && curBufPtr < BUF_SIZE; i++ ) {
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
	buf[curBufPtr++] = GI_GET_BYTE(base + (offset-target));

      target += length;
    }

    if (i >= GI_NUM_SECTIONS) {
      for ( ; offset < target + 8 && curBufPtr < BUF_SIZE; offset++ )
	buf[curBufPtr++] = 0;
      if (offset >= target + 8)
	allDone = TRUE;
    }

  }

  task void writeData() {
    uint32_t offset = (uint32_t)curBuf * (uint32_t)BUF_SIZE + DELUGE_CRC_BLOCK_SIZE;
    if (call DataWrite.write(DELUGE_GOLDEN_IMAGE_NUM, offset, buf, BUF_SIZE) == FAIL)
      post writeData();
  }

  command result_t StdControl.init() { 
    call DelugeControl.init();
    call MgmtQueryControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() { 
    call MetadataControl.start(); 
    call MgmtQueryControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() { 
    return SUCCESS; 
  }

  event void Storage.loadImagesDone(result_t result) {
    ;
  }

  event result_t MetadataControl.initDone() {
    return SUCCESS;
  }

  task void eraseData() {
    if (call Metadata.setupNewImage(&imgDesc) == FAIL)
      post eraseData();
  }

  task void clrWP() {
    if (call FlashWP.clrWP() == FAIL)
      post clrWP();
  }

  task void setWP() {
    if (call FlashWP.setWP() == FAIL)
      post setWP();
  }
  
  event result_t MetadataControl.startDone() { 

    uint8_t isGoldenImgLoaded;

    call IFlash.read((uint8_t*)TOSBOOT_FLAGS_ADDR, &isGoldenImgLoaded, 
		     sizeof(isGoldenImgLoaded));

    // don't clone to flash if golden image has been loaded
    if (!(isGoldenImgLoaded & TOSBOOT_GOLDEN_IMG_LOADED))
      return call DelugeControl.start();
    
    // haven't cloned to flash before
    if (call FlashWP.clrWP() == FAIL)
      post clrWP();

    return SUCCESS; 

  }

  event result_t MetadataControl.stopDone() { 
    return SUCCESS; 
  }

  event result_t FlashWP.clrWPDone(result_t result) {

    uint8_t* tmp = (uint8_t*)&imgDesc;
    uint8_t i;

    allDone = FALSE;
    curBuf = 0;
    
    imgDesc.vNum = 0;
    imgDesc.imgNum = DELUGE_GOLDEN_IMAGE_NUM;
    imgDesc.numPgsComplete = 1;
    imgDesc.numPgs = 1;
    imgDesc.crc = 0;

    for ( i = 0; i < 4; i++ )
      imgDesc.crc = crcByte(imgDesc.crc, tmp[i]);

    if (call Metadata.setupNewImage(&imgDesc) == FAIL)
      post eraseData();
    return SUCCESS;
  }

  void completeWrite() {
    DelugeNodeDesc nodeDesc;
    uint32_t addr;
    uint8_t  tmp8;

    // mark that golden image has been written
    call IFlash.read((uint8_t*)TOSBOOT_FLAGS_ADDR, &tmp8, sizeof(tmp8));
    tmp8 &= ~TOSBOOT_GOLDEN_IMG_LOADED;
    call IFlash.write((uint8_t*)TOSBOOT_FLAGS_ADDR, &tmp8, sizeof(tmp8));

    // write out node descriptor
    nodeDesc.vNum = 0;
    nodeDesc.imgNum = 0;
    nodeDesc.dummy = 0;
    nodeDesc.crc = 0;
    call IFlash.write((uint16_t*)IFLASH_NODE_DESC_ADDR, &nodeDesc, sizeof(nodeDesc));

    // have bootloader reprogram chip to verify that everything is working
    tmp8 = TOSBOOT_GESTURE_MAX_COUNT;
    call IFlash.write((uint8_t*)TOSBOOT_GESTURE_COUNT_ADDR, &tmp8, sizeof(tmp8));
    addr = call Storage.imgNum2Addr(DELUGE_GOLDEN_IMAGE_NUM) + DELUGE_IDENT_SIZE;
    // addr = 0xf0180
    call IFlash.write((uint8_t*)TOSBOOT_NEW_IMG_START_ADDR, &addr, sizeof(addr));

    call NetProg.reboot();
  }

  event result_t FlashWP.setWPDone(result_t result) {
    completeWrite();
    return SUCCESS;
  }

  event void DataWrite.writeDone(storage_result_t result) {

    if (result == STORAGE_FAIL) {
      // something went wrong, try again
      post writeData();
      return;
    }

    curBuf++;
    
    // if all done, sync image data
    if (allDone) {
      if (call FlashWP.setWP() == FAIL)
	post setWP();
      return;
    }

    call Leds.set(curBuf);

    fillBuf();
    post writeData();

  }

  event void DataWrite.eraseDone(result_t result) { ; }

  event void Metadata.setupNewImageDone(result_t result) {
    // start cloning
    call Metadata.receivedPage(DELUGE_GOLDEN_IMAGE_NUM, 0);
    fillBuf();
    post writeData();
  }

  event void Metadata.receivedPageDone(result_t result) { ; }

}
