// $Id: ByteEEPROMC.nc,v 1.2 2004/04/19 17:10:58 idgay Exp $

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
*/

includes ByteEEPROMInternal;
module ByteEEPROMC {
  provides {
    interface WriteData[uint8_t id];
    interface LogData[uint8_t id];
    interface LogData as PersistentLog[uint8_t id];
    interface ReadData[uint8_t id];
  }
  uses {
    command RegionSpecifier *getRegion(uint8_t id, bool check);
    interface PageEEPROM;
    interface Leds;
    interface IPersistent;
  }
}
implementation {
  enum {
    S_IDLE,
    S_READ,
    S_WRITE,
    S_APPEND,
    S_SYNC,
    S_ERASE,
    S_PAPPEND,
    S_PSYNC,
    S_PERASE
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

  RegionSpecifier *newRequest(uint8_t clientId) {
    if (S_IDLE != state)
      return NULL;

    appID = clientId;

    return call getRegion(clientId, TRUE);
  }
  
  result_t startOp(RegionSpecifier *region, uint32_t offset,
		   uint8_t *buffer, uint32_t count) {
    // the first byte actually read from
    startAddr = region->startByte + offset;
    // the byte addr before stopAddr is the last byte we actually read
    stopAddr = region->startByte + offset + count;

    //offset out of range, or trying to read too many bytes
    if ((startAddr < region->startByte) ||
	(startAddr >= region->stopByte))
      return FAIL;
    if ((stopAddr <= region->startByte) ||
	(stopAddr > region->stopByte))
      return FAIL;

    // We note if we're writing the last byte (append needs to know this to
    // avoid erasing the first page of the next region)
    writesLastByte = stopAddr == region->stopByte;
    
    // Save the request data in our state vars
    numBytes = count;
    dataBuffer = buffer;
    dataBufferOffset = 0;

    return SUCCESS;
  }
  
  result_t newBufferRequest(uint8_t clientId, uint32_t offset,
			    uint8_t *buffer, uint32_t count) {
    RegionSpecifier *region = newRequest(clientId);
    
    if (region == NULL)
      return FAIL;

    return startOp(region, offset, buffer, count);
  }

  void advance() {
    RegionSpecifier *region = call getRegion(appID, FALSE);

    region->appendOffset += numBytes;
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
	  advance();
	signal LogData.appendDone[appID](dataBuffer, numBytes, success);
	break;
      case S_PAPPEND:
	if (success)
	  advance();
	signal PersistentLog.appendDone[appID](dataBuffer, numBytes, success);
	break;
      case S_SYNC:
	signal LogData.syncDone[appID](success); 
	break;
      case S_PSYNC:
	signal PersistentLog.syncDone[appID](success); 
	break;
      case S_ERASE:
	signal LogData.eraseDone[appID](success); 
	break;
      case S_PERASE:
	signal PersistentLog.eraseDone[appID](success); 
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
      case S_WRITE:  case S_APPEND: case S_PAPPEND:
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

  event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc) {
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
	else if (state == S_PAPPEND && (startAddr & PAGE_SIZE_MASK) == 0)
	  {
	    eeprompage_t page = (startAddr - 1) >> TOS_EEPROM_PAGE_SIZE_LOG2;
	    uint32_t startOffset = startAddr - dataBufferOffset;
	    eeprompageoffset_t offset;

	    /* add per-page-info to persistent appends when we finish a page */
	    if (page == startOffset >> TOS_EEPROM_PAGE_SIZE_LOG2)
	      offset = startOffset & PAGE_SIZE_MASK;
	    else
	      offset = PAGE_SIZE;
	    check(call IPersistent.finishPage(page, offset));
	  }
	else
	  continueOp();
      }
    return SUCCESS;
  }

  // Default finishPage to allow PersistentLogger to be optional
  default command result_t IPersistent.finishPage(eeprompage_t page, eeprompageoffset_t lastRecord) {
    return FAIL;
  }

  event result_t IPersistent.finishPageDone(result_t success) {
    if (!success)
      completeOp(FAIL);
    else if (state == S_PSYNC)
      check(call PageEEPROM.syncAll());
    else // state == S_PAPPEND
      check(call PageEEPROM.flush((startAddr >> TOS_EEPROM_PAGE_SIZE_LOG2) - 1));
    return SUCCESS;
  }

  event result_t PageEEPROM.flushDone(result_t result) {
    if (!result)
      completeOp(FAIL);
    else if (state == S_APPEND)
      check(call PageEEPROM.erase(startAddr >> TOS_EEPROM_PAGE_SIZE_LOG2,
				  TOS_EEPROM_PREVIOUSLY_ERASED));
    else // state == S_PAPPEND
      continueOp();
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

  result_t append(uint8_t s, uint8_t id, uint8_t *buffer, uint32_t n) {
    RegionSpecifier *region = newRequest(id);

    // The use of appendOffset - 1 will make newBufferRequest fail if
    // appends are not currently allowed
    if (!region ||
	!startOp(region, region->appendOffset - 1, buffer, n))
      return FAIL;

    state = s;
    continueOp();

    return SUCCESS;
  }

  uint32_t currentOffset(uint8_t id) {
    RegionSpecifier *region = call getRegion(id, TRUE);

    if (region)
      return region->appendOffset - 1;
    else
      return (uint32_t)-1;
  }
  
  result_t erase(uint8_t s, uint8_t clientId) {
    RegionSpecifier *region = newRequest(clientId);

    if (!region)
      return FAIL;

    /* We erase backwards so that the first page (where we will start
       appending) is in the cache in an "erased" state */
    state = s;
    startAddr = region->startByte >> TOS_EEPROM_PAGE_SIZE_LOG2;
    stopAddr = (region->stopByte - 1) >> TOS_EEPROM_PAGE_SIZE_LOG2;
    region->appendOffset = 1; // start appending at offset 0

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

  command result_t LogData.append[uint8_t id](uint8_t *buffer, uint32_t n) {
    return append(S_APPEND, id, buffer, n);
  }

  command uint32_t LogData.currentOffset[uint8_t id]() {
    return currentOffset(id);
  }
  
  command result_t LogData.erase[uint8_t clientId]() {
    return erase(S_ERASE, clientId);
  }

  command result_t LogData.sync[uint8_t clientId]() {
    RegionSpecifier *region = newRequest(clientId);

    if (!region)
      return FAIL;

    state = S_SYNC;
    region->appendOffset = 0; // disable append
    check(call PageEEPROM.syncAll());

    return SUCCESS;
  }

  event result_t PageEEPROM.syncDone(result_t result) { 
    completeOp(result);
    return SUCCESS;
  }

  command result_t PersistentLog.append[uint8_t id](uint8_t *buffer, uint32_t n) {
    return append(S_PAPPEND, id, buffer, n);
  }

  command uint32_t PersistentLog.currentOffset[uint8_t id]() {
    return currentOffset(id);
  }
  
  command result_t PersistentLog.erase[uint8_t clientId]() {
    return erase(S_PERASE, clientId);
  }

  command result_t PersistentLog.sync[uint8_t clientId]() {
    RegionSpecifier *region = newRequest(clientId);
    uint32_t offset;

    if (!region)
      return FAIL;

    state = S_PSYNC;
    offset = region->appendOffset - 1;
    check(call IPersistent.finishPage(offset >> TOS_EEPROM_PAGE_SIZE_LOG2,
				      offset & PAGE_SIZE_MASK));
    return SUCCESS;
  }

  default event result_t WriteData.writeDone[uint8_t id](uint8_t *data, uint32_t numBytesWrite, result_t success) {
    return SUCCESS;
  }

  default event result_t ReadData.readDone[uint8_t id](uint8_t *buffer, uint32_t numBytesRead, result_t success) {
    return SUCCESS;
  }

  default event result_t PersistentLog.appendDone[uint8_t id](uint8_t *data, uint32_t numBytesWrite, result_t success) {
    return SUCCESS;
  }

  default event result_t PersistentLog.eraseDone[uint8_t id](result_t success) {
    return SUCCESS;
  }

  default event result_t PersistentLog.syncDone[uint8_t id](result_t success) {
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
}
