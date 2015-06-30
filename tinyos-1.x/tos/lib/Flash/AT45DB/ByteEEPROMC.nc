// $Id: ByteEEPROMC.nc,v 1.1 2005/07/11 23:36:08 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */



/*
  --Initialization--
  Each app that uses ByteEEPROM should call init() before Request
  or RequestAddr.  It is safe to call init multiple times.

  --Start--
  Each app that uses ByteEEPROM should call start() in its own
  start method. It is safe to call start multiple times.

  --Interface Wiring--
  apps that use this component should wire specific instances of AllocationReq,
  SendDataToMapped, and ReadDataToMapped. The reason for having these interfaces
  parameterized is so ByteEEPROM can communicate with each app separately.
  For example, when an app requests a read, when the read completes, this ByteEEPROM
  can then signal a readDone to only the application that requested it; similar is the
  case for writes.

  --Notes--
  TOS_EEPROM_MAX_LINES = 0x80000 >> TOS_EEPROM_LOG2_LINE_SIZE is the maximum number of
  lines. Therefore, (TOS_EEPROM_MAX_LINES - 1) << TOS_EEPROM_LOG2_LINE_SIZE is the last
  line/page that can be requested.
  
*/

includes ByteEEPROMInternal;
module ByteEEPROMC {
  provides {
    interface WriteData[uint8_t id];
    interface LogData[uint8_t id];
    interface ReadData[uint8_t id];
  }
  uses {
    command RegionSpecifier *getRegion(uint8_t id);
    interface PageEEPROM;
    interface Leds;
  }
}
implementation {
  enum {
    S_IDLE,
    S_READ,
    S_WRITE,
    S_APPEND,
    S_SYNC,
    S_ERASE
  };

  uint8_t state;
  
  uint8_t appID;
  uint32_t startAddr;
  uint32_t stopAddr;
  uint32_t numBytes;
  uint32_t dataBufferOffset;
  uint8_t *dataBuffer;
  bool writesLastByte;

  enum {
    NREGIONS = uniqueCount("ByteEEPROM"),
    PAGE_SIZE = 1 << TOS_EEPROM_PAGE_SIZE_LOG2,
    PAGE_SIZE_MASK = PAGE_SIZE - 1
  };

  // appendOffsets for the regions. They are stored as "real offset"+1 to
  // provide easy handling of the "append offset" invalid condition
  uint32_t appendOffset[NREGIONS];

  RegionSpecifier *newRequest(uint8_t clientId) {
    if (S_IDLE != state)
      return NULL;

    appID = clientId;

    return call getRegion(clientId);
  }
  
  result_t newBufferRequest(uint8_t clientId, uint32_t offset,
			    uint8_t *buffer, uint32_t count) {
    RegionSpecifier *mappedRegion = newRequest(clientId);
    
    if (mappedRegion == NULL)
      return FAIL;
    
    // the first byte actually read from
    startAddr = mappedRegion->startByte + offset;
    // the byte addr before stopAddr is the last byte we actually read
    stopAddr = mappedRegion->startByte + offset + count;

    //offset out of range, or trying to read too many bytes
    if ((startAddr < mappedRegion->startByte) ||
	(startAddr >= mappedRegion->stopByte))
      return FAIL;
    if ((stopAddr <= mappedRegion->startByte) ||
	(stopAddr > mappedRegion->stopByte))
      return FAIL;

    // We note if we're writing the last byte (append needs to know this to
    // avoid erasing the first page of the next region)
    writesLastByte = stopAddr == mappedRegion->stopByte;
    
    // Save the request data in our state vars
    numBytes = count;
    dataBuffer = buffer;
    dataBufferOffset = 0;

    return SUCCESS;
  }
  
  void completeOp(result_t success) {
    uint8_t op = state;

    state = S_IDLE;
    switch (op)
      {
      case S_READ:
	signal ReadData.readDone[appID](dataBuffer, numBytes, success);
	break;
      case S_WRITE:
	signal WriteData.writeDone[appID](dataBuffer, numBytes, success);
	break;
      case S_APPEND:
	if (success)
	  appendOffset[appID] += numBytes;
	signal LogData.appendDone[appID](dataBuffer, numBytes, success);
	break;
      case S_SYNC:
	signal LogData.syncDone[appID](success); 
	break;
      case S_ERASE:
	signal LogData.eraseDone[appID](success); 
	break;
      }
  }

  task void successTask() {
    completeOp(SUCCESS);
  }

  task void failTask() {
    completeOp(FAIL);
  }

  void check(result_t success) {
    if (!success)
      post failTask();
  }

  void continueOp() {
    eeprompage_t sPage = startAddr >> TOS_EEPROM_PAGE_SIZE_LOG2;
    eeprompage_t ePage = stopAddr >> TOS_EEPROM_PAGE_SIZE_LOG2;
    eeprompageoffset_t offset, count;

    if (startAddr == stopAddr)
      {
	post successTask();
	return;
      }

    offset = startAddr & PAGE_SIZE_MASK;
    if (sPage == ePage)
      count = stopAddr - startAddr;
    else
      count = PAGE_SIZE - offset;

    switch (state)
      {
      case S_READ:
	check(call PageEEPROM.read(sPage, offset, dataBuffer + dataBufferOffset, count));
	break;
      case S_WRITE:  case S_APPEND:
	check(call PageEEPROM.write(sPage, offset, dataBuffer + dataBufferOffset, count));
	break;
      }

    dataBufferOffset += count;
    startAddr += count;
  }

  event result_t PageEEPROM.readDone(result_t success) {
    if (success == FAIL)
      completeOp(FAIL);
    else 
      continueOp();
    return SUCCESS;
  }

  event result_t PageEEPROM.writeDone(result_t success) {
    if (success == FAIL)
      completeOp(FAIL);
    else 
      {
	if (state == S_APPEND && (startAddr & PAGE_SIZE_MASK) == 0 &&
	    !(writesLastByte && startAddr == stopAddr))
	  /* If an appending write filled the page, flush the last page and
	     remind the EEPROM that the next page has been erased.
	     Semi-hack: if this append is writing the last byte of a region
	     whose size is the multiple of the page size, we don't want to
	     erase the next page (as it belongs to another region). We
	     detect this with the writesLastByte boolean... */
	  check(call PageEEPROM.flush((startAddr >> TOS_EEPROM_PAGE_SIZE_LOG2) - 1));
	else
	  continueOp();
      }
    return SUCCESS;
  }

  event result_t PageEEPROM.flushDone(result_t result) {
    check(call PageEEPROM.erase(startAddr >> TOS_EEPROM_PAGE_SIZE_LOG2,
				TOS_EEPROM_PREVIOUSLY_ERASED));
    return SUCCESS;
  }

  command result_t ReadData.read[uint8_t id](uint32_t offset, uint8_t *buffer, uint32_t numBytesRead) {
    if (newBufferRequest(id, offset, buffer, numBytesRead) == FAIL)
      return FAIL;

    state = S_READ;
    continueOp();

    return SUCCESS;
  }
  
  command result_t WriteData.write[uint8_t id](uint32_t offset, uint8_t *buffer, uint32_t numBytesWrite) {
    if (newBufferRequest(id, offset, buffer, numBytesWrite) == FAIL)
      return FAIL;

    state = S_WRITE;
    continueOp();

    return SUCCESS;
  }
  
  command result_t LogData.append[uint8_t id](uint8_t *buffer, uint32_t numBytesWrite) {
    // The use of appendOffset - 1 will make newBufferRequest fail if
    // appends are not currently allowed
    if (newBufferRequest(id, appendOffset[id] - 1, buffer, numBytesWrite) == FAIL)
      return FAIL;

    state = S_APPEND;
    continueOp();

    return SUCCESS;
  }

  command uint32_t LogData.currentOffset[uint8_t id]() {
    if (call getRegion(id))
      return appendOffset[id] - 1;
    else
      return (uint32_t)-1;
  }
  
  command result_t LogData.sync[uint8_t clientId]() {
    if (!newRequest(clientId))
      return FAIL;
    appendOffset[clientId] = 0; // disable append
    state = S_SYNC;
    check(call PageEEPROM.syncAll());
    return SUCCESS;
  }

  event result_t PageEEPROM.syncDone(result_t result) { 
    completeOp(result);
    return SUCCESS;
  }

  command result_t LogData.erase[uint8_t clientId]() {
    RegionSpecifier *mappedRegion = newRequest(clientId);

    if (!mappedRegion)
      return FAIL;

    /* We erase backwards so that the first page (where we will start
       appending) is in the cache in an "erased" state */
    state = S_ERASE;
    startAddr = mappedRegion->startByte >> TOS_EEPROM_PAGE_SIZE_LOG2;
    stopAddr = (mappedRegion->stopByte - 1) >> TOS_EEPROM_PAGE_SIZE_LOG2;
    appendOffset[clientId] = 1; // start appending at offset 0

    check(call PageEEPROM.erase(stopAddr, TOS_EEPROM_ERASE));

    return SUCCESS;
  }

  event result_t PageEEPROM.eraseDone(result_t success) {
    if (!success)
      completeOp(success);
    else if (state == S_APPEND)
      continueOp();
    else
      {
	if (startAddr == stopAddr)
	  completeOp(SUCCESS);
	else
	  {
	    stopAddr--;
	    check(call PageEEPROM.erase(stopAddr, TOS_EEPROM_ERASE));
	  }
      }
    return SUCCESS;
  }
  
  default event result_t WriteData.writeDone[uint8_t id](uint8_t *data, uint32_t numBytesWrite, result_t success) {
    return SUCCESS;
  }

  default event result_t ReadData.readDone[uint8_t id](uint8_t *buffer, uint32_t numBytesRead, result_t success) {
    return SUCCESS;
  }

  default event result_t LogData.appendDone[uint8_t id](uint8_t *data, uint32_t numBytesWrite, result_t success) {
    return SUCCESS;
  }

  default event result_t LogData.eraseDone[uint8_t id](result_t success) {
    return SUCCESS;
  }

  default event result_t LogData.syncDone[uint8_t id](result_t success) {
    return SUCCESS;
  }

  event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc) {
    return SUCCESS;
  }
}
