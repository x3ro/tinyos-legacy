/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  Author: Nelson Lee
 *  Created: 8/27/02
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


includes ByteEEPROM;
module ByteEEPROMC {
  provides {
    interface AllocationReq[uint8_t id];
    interface WriteDataToMapped[uint8_t id];
    interface ReadDataToMapped[uint8_t id];
    interface StdControl;
  }

  uses {
    interface StdControl as EEPROMStdControl;
    interface EEPROMRead;
    interface EEPROMWrite;
    interface Leds;
  }
}

implementation {
  enum {
    IDLE,
    READING_START_PAGE,
    READING_END_PAGE,
    READING,
    READING_ONE_PAGE,
    // writing occurs as follows: reads pages that contain overlap. For instance, if writing last 3 bytes of the start page and first 2 bytes of end page,
    // the pages must first be read, bytes to be written overwritten in the buffer, and the entire page written out to the eeprom.
    WRITING_READ_START_PAGE,
    WRITING_READ_END_PAGE,
    WRITING_READ_ONE_PAGE,
    WRITING,
    WRITING_END,
    WRITING_ONE_PAGE
  };
  
  
  
  uint8_t state;
  uint8_t count;
  
  bool initialized;
  bool allocated;
  
  uint32_t maxBytes;
  
  uint8_t startPageBuffer[16];
  uint8_t stopPageBuffer[16];

  uint8_t appID;
  uint8_t currentMappedID;
  
  uint32_t startAddr;
  uint32_t stopAddr;
  uint32_t numBytes;
  uint32_t byteOffset;
  
  uint8_t* dataReadBuffer;
  
  uint8_t* dataToWrite;
  uint8_t* dataToWriteIncludingOffset;
  
  uint16_t txCountPages;
  uint16_t totalCountPages;
  
  bool overlapStartPage;
  bool overlapEndPage;

  RegionSpecifier* allocatedHead;
  RegionSpecifier* allocatedTail;
  
  RegionSpecifier* requestWithAddrHead;
  RegionSpecifier* requestWithAddrTail;
  RegionSpecifier* requestHead;
  RegionSpecifier* requestTail;

  RegionSpecifier* findAllocatedRegion(uint8_t mappedID) {
    RegionSpecifier* currentRegion = allocatedHead;
    while (currentRegion != NULL) {
      if (currentRegion->id == mappedID)
	return currentRegion;
      
      currentRegion = currentRegion->next;
    }
    return NULL;
  }


  event result_t EEPROMWrite.endWriteDone(result_t success) {
    // something is seriously wrong if this is the case
    if (WRITING_END != state) {
      dbg(DBG_LOG, "LOGGER: received endWriteDone when not in proper state, state: %d", state);
    }

    else {
      state = IDLE;
      signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, success);
    }
    return success;
  }


  event result_t EEPROMWrite.writeDone(uint8_t* buffer) {
    // something is seriously wrong if this is the case
    if (overlapStartPage) {
      dbg(DBG_LOG, "LOGGER: received writeDone in wrong state, state: %d,  or overlapStartPage true when it's not supposed to be, overlapStartPage: %d,", state, overlapStartPage);
      return FAIL;
    }

    if (WRITING == state) {
    
      // check if we have written all the pages supposed to have been written
      if (txCountPages == totalCountPages) {
	state = WRITING_END;
	if (FAIL == call EEPROMWrite.endWrite()) {
	  state = IDLE;
	  signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	  
	}
      }
      
      // of the start and end pages, only the end may not have been written out yet
      else if (overlapEndPage) {
	if (FAIL == call EEPROMWrite.write(stopAddr >> TOS_EEPROM_LOG2_LINE_SIZE, stopPageBuffer)) {
	  state = IDLE;
	  signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	}
	overlapEndPage = FALSE;
	txCountPages++;
      }
      
      // else we continue writing pages from dataToWrite + byteOffset
      else {
	if (FAIL == call EEPROMWrite.write((startAddr + byteOffset) >> TOS_EEPROM_LOG2_LINE_SIZE, dataToWrite + byteOffset)) {
	  state = IDLE;
	  signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	}
	byteOffset += 16;
	txCountPages++;
      }
    }

    return SUCCESS;
  }
  

  command result_t WriteDataToMapped.write[uint8_t id](uint8_t mappedID, uint32_t offset, uint8_t* data, uint32_t numBytesWrite) {
    RegionSpecifier* mappedRegion = findAllocatedRegion(mappedID);
    
    if (IDLE != state)
      return FAIL;
    
    //mappedID is invalid
    if (mappedRegion == NULL)
      return FAIL;

    // the first byte actually written out to
    startAddr = mappedRegion->startByte + offset;
    // the byte addr before stopAddr is the last byte we actually write
    stopAddr = mappedRegion->startByte + offset + numBytesWrite;

    //offset out of range, or trying to write too many bytes
    if ((startAddr < mappedRegion->startByte) ||
	(startAddr >= mappedRegion->stopByte))
      return FAIL;
    if ((stopAddr <= mappedRegion->startByte) ||
	(stopAddr > mappedRegion->stopByte))
      return FAIL;



    // numBytes specifies the number of bytes we need to write out
    numBytes = numBytesWrite;
    // dataToWrite is a pointer to the data we are writing
    dataToWrite = data;
    // totalCountPages specifies the number of pages that need to be transferred
    totalCountPages = 1 + (stopAddr-1 >> TOS_EEPROM_LOG2_LINE_SIZE) - (startAddr >> TOS_EEPROM_LOG2_LINE_SIZE);
    // the mapped ID passed to write is stored as a global variable for later access
    currentMappedID = mappedID;
    // reset the offset used to index into dataToWrite and startAddr when writing entire pages
    byteOffset = 0;

    appID = id;

    // special case if writing 1 page
    if (totalCountPages == 1) {
      state = WRITING_READ_ONE_PAGE;
      if (FAIL == call EEPROMRead.read(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, startPageBuffer)) {
	state = IDLE;
	signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	return FAIL;
      }
    }

    //read what's already in the EEPROM at the start and end pages
    //and then write
    else if (((startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) != 0) &&
	((stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) != 0)) {
      overlapStartPage = TRUE;
      overlapEndPage = TRUE;
      
      state = WRITING_READ_START_PAGE;
      if (FAIL == call EEPROMRead.read(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, startPageBuffer)) {
	state = IDLE;
	signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	return FAIL;
      }

	
      
    }
    //read only the start page
    else if ((startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) != 0) {
      overlapStartPage = TRUE;
      overlapEndPage = FALSE;

      state = WRITING_READ_START_PAGE;
      if (FAIL == call EEPROMRead.read(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, startPageBuffer)) {
	state = IDLE;
	signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	return FAIL;
      }
      

      
    }
    //read only the end page
    else if ((stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) != 0) {
      overlapStartPage = FALSE;
      overlapEndPage = TRUE;

      state = WRITING_READ_END_PAGE;
      if (FAIL == call EEPROMRead.read(stopAddr >> TOS_EEPROM_LOG2_LINE_SIZE, stopPageBuffer)) {
	state = IDLE;
	signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	return FAIL;
      }
      
    }
    //no reading is done, writing entire pages
    else {
      overlapEndPage = FALSE;
      overlapStartPage = FALSE;
      
      state = WRITING;
      if ((FAIL == call EEPROMWrite.startWrite()) ||
	  (FAIL == call EEPROMWrite.write(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, dataToWrite))) {
	state = IDLE;
	signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	return FAIL;
      }

	
      byteOffset = 16;
      txCountPages = 1;
      
    }
    return SUCCESS;
  }

  event result_t EEPROMRead.readDone(uint8_t* buffer, result_t success) {
    uint8_t overlapNumBytes;

    // failure cases, signals either writeDone() or readDone()
    if (FAIL == success) {
      if ((WRITING_READ_START_PAGE == state) ||
	  (WRITING_READ_END_PAGE == state))
	{
	  state = IDLE;
	  signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	  
	}
      else if ((READING == state) ||
	       (READING_START_PAGE == state) ||
	       (READING_END_PAGE == state)) {
	state = IDLE;
	signal ReadDataToMapped.readDone[appID](currentMappedID, dataReadBuffer, numBytes, FAIL);
      }
    }

    
    else {
      if (WRITING_READ_START_PAGE == state) {
	// finished reading in start page, change bytes that overlap
	overlapNumBytes = TOS_EEPROM_LINE_SIZE - (startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK);
	memcpy(startPageBuffer + (startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK), dataToWrite, overlapNumBytes);
	byteOffset = overlapNumBytes;
	// if there is overlap for end page, read in end page and set state accordingly
	if (overlapEndPage) {
	  state = WRITING_READ_END_PAGE;
	  if (FAIL == call EEPROMRead.read(stopAddr >> TOS_EEPROM_LOG2_LINE_SIZE, stopPageBuffer)) {
	    state = IDLE;
	    signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	  }
	}
	// else we start writing out entire pages starting with the overlapped start page
	else {
	  state = WRITING;

	  if ((FAIL == call EEPROMWrite.startWrite()) ||
	      (FAIL == call EEPROMWrite.write(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, startPageBuffer))) {
	    state = IDLE;
	    signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	    
	  }
	    
	  txCountPages = 1;
	  overlapStartPage = FALSE;
	}
      }
      else if (WRITING_READ_END_PAGE == state) {
	// finished reading in end page, change bytes that overlap
	overlapNumBytes = stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK;
	memcpy(stopPageBuffer, dataToWrite + numBytes - overlapNumBytes, overlapNumBytes);

	state = WRITING;
	if (FAIL == call EEPROMWrite.startWrite()) {
	  state = IDLE;
	  signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	}
	
	// start writing out entire pages starting with the overlapped start page
	if (overlapStartPage) {
	  if (FAIL == call EEPROMWrite.write(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, startPageBuffer)) {
	    state = IDLE;
	    signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	  }
	  overlapStartPage = FALSE;
	}
	// start writing out entire pages starting with the overlapped end page; note the else clause is run
	// only when the end page has overlap
	else {
	  if (FAIL == call EEPROMWrite.write(stopAddr >> TOS_EEPROM_LOG2_LINE_SIZE, stopPageBuffer)) {
	    state = IDLE;
	    signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	  }
	  overlapEndPage = FALSE;
	}
	txCountPages = 1;
      }
      else if (WRITING_READ_ONE_PAGE == state) {
	overlapNumBytes = TOS_EEPROM_LINE_SIZE - (startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) - ((TOS_EEPROM_LINE_SIZE - (stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK)) % TOS_EEPROM_LINE_SIZE);
	memcpy(startPageBuffer + (startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK), dataToWrite, overlapNumBytes);
	
	state = WRITING;
	byteOffset += overlapNumBytes;
	if ((FAIL == call EEPROMWrite.startWrite()) ||
	    (FAIL == call EEPROMWrite.write(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, startPageBuffer))) {
	  state = IDLE;
	  signal WriteDataToMapped.writeDone[appID](currentMappedID, dataToWrite, numBytes, FAIL);
	}
	txCountPages = 1;
      }
    
      // reading at least 2 pages
      else if (READING_START_PAGE == state) {
	overlapNumBytes = TOS_EEPROM_LINE_SIZE - (startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK);
	memcpy(dataReadBuffer, startPageBuffer + (startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK), overlapNumBytes);
	byteOffset = overlapNumBytes;


	// reading two pages and there is overlap in the end page
	if (overlapEndPage && (txCountPages == totalCountPages - 1)) {
	  if (FAIL == (call EEPROMRead.read((startAddr + byteOffset) >> TOS_EEPROM_LOG2_LINE_SIZE, stopPageBuffer))) {
	    state = IDLE;
	    signal ReadDataToMapped.readDone[appID](currentMappedID, dataReadBuffer, numBytes, FAIL);
	  }
	  else {
	    // don't change byteOffset, need to copy bytes of last page into dataReadBuffer still
	    txCountPages++;
	    state = READING_END_PAGE;
	  }
	  
	}
	// set state to READING and read in entire next page into buffer
	else {
	  if (FAIL == (call EEPROMRead.read((startAddr + byteOffset) >> TOS_EEPROM_LOG2_LINE_SIZE, dataReadBuffer + byteOffset))) {
	    state = IDLE;
	    signal ReadDataToMapped.readDone[appID](currentMappedID, dataReadBuffer, numBytes, FAIL);
	  }
	  else {
	    byteOffset += TOS_EEPROM_LINE_SIZE;
	    txCountPages++;
	    state = READING;
	  }
	}
	
      }
      

      else if (READING == state) {
	// check if last page read
	if (txCountPages == totalCountPages) {
	  state = IDLE;
	  signal ReadDataToMapped.readDone[appID](currentMappedID, dataReadBuffer, numBytes, SUCCESS);
	}
	else if ((txCountPages == totalCountPages - 1) && overlapEndPage) {
	  if (FAIL == (call EEPROMRead.read((startAddr + byteOffset) >> TOS_EEPROM_LOG2_LINE_SIZE, stopPageBuffer))) {
	    state = IDLE;
	    signal ReadDataToMapped.readDone[appID](currentMappedID, dataReadBuffer, numBytes, FAIL);
	  }
	  else {
	    state = READING_END_PAGE;
	    txCountPages++;
	  }


	}
	
	else {
	  if (FAIL == (call EEPROMRead.read((startAddr + byteOffset) >> TOS_EEPROM_LOG2_LINE_SIZE, dataReadBuffer + byteOffset))) {
	    state = IDLE;
	    signal ReadDataToMapped.readDone[appID](currentMappedID, dataReadBuffer, numBytes, FAIL);
	  }
	  else {
	    byteOffset += TOS_EEPROM_LINE_SIZE;
	    txCountPages++;
	  }
	}	
      }

      else if (READING_END_PAGE == state) {
	overlapNumBytes = stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK;
	memcpy(dataReadBuffer + numBytes - overlapNumBytes, stopPageBuffer, overlapNumBytes);
	state = IDLE;
	byteOffset += overlapNumBytes;
	signal ReadDataToMapped.readDone[appID](currentMappedID, dataReadBuffer, numBytes, SUCCESS);
      }

      
      // this is a special case, handled separately from all other cases (reading <= 1 page of EEPROM)
      else if (READING_ONE_PAGE == state) {
	overlapNumBytes = TOS_EEPROM_LINE_SIZE - (startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) - ((TOS_EEPROM_LINE_SIZE - (stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK)) % TOS_EEPROM_LINE_SIZE);
	memcpy(dataReadBuffer, startPageBuffer + (startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK), overlapNumBytes);
	
	state = IDLE;
	byteOffset += overlapNumBytes;
	signal ReadDataToMapped.readDone[appID](currentMappedID, dataReadBuffer, numBytes, SUCCESS);   
      }
      else {
	dbg(DBG_LOG, "LOGGER: received readDone when not in proper state, state: %d", state);
	return FAIL;
      }
      
      
    }
    return SUCCESS;
  }

  
  command result_t ReadDataToMapped.read[uint8_t id](uint8_t mappedID, uint32_t offset, uint8_t* buffer, uint32_t numBytesRead) {
    RegionSpecifier* mappedRegion = findAllocatedRegion(mappedID);
    
    if (IDLE != state)
      return FAIL;
    
    //mappedID is invalid
    if (mappedRegion == NULL)
      return FAIL;
    
    // the first byte actually read from
    startAddr = mappedRegion->startByte + offset;
    // the byte addr before stopAddr is the last byte we actually read
    stopAddr = mappedRegion->startByte + offset + numBytesRead;

    //offset out of range, or trying to read too many bytes
    if ((startAddr < mappedRegion->startByte) ||
	(startAddr >= mappedRegion->stopByte))
      return FAIL;
    if ((stopAddr <= mappedRegion->startByte) ||
	(stopAddr > mappedRegion->stopByte))
      return FAIL;
    
    // numBytes specifies the number of bytes we need to read
    numBytes = numBytesRead;
    // dataReadBuffer is a pointer to the buffer of memory we are reading to
    dataReadBuffer = buffer;
    // totalCountPages specifies the number of pages that need to be transferred
    totalCountPages = 1 + (stopAddr-1 >> TOS_EEPROM_LOG2_LINE_SIZE) - (startAddr >> TOS_EEPROM_LOG2_LINE_SIZE);
    // the mapped ID passed to write is stored as a global variable for later access
    currentMappedID = mappedID;
    // reset the offset used to offset dataReadBuffer
    byteOffset = 0;

    appID = id;

    // special case, reading only one page in EEPROM
    if (totalCountPages == 1) {
      state = READING_ONE_PAGE;
      if (((startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) == 0) &&
	  ((stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) == 0)) {
	overlapStartPage = FALSE;
	overlapEndPage = FALSE;
      }
      else if ((startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) == 0) {
	overlapStartPage = FALSE;
	overlapEndPage = TRUE;
      }
      else if ((stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) == 0) {
	overlapStartPage = TRUE;
	overlapEndPage = FALSE; 
      }
      else {
	overlapStartPage = TRUE;
	overlapEndPage = TRUE;
      }

      if (FAIL == (call EEPROMRead.read(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, startPageBuffer))) {
	state = IDLE;
	return FAIL;
      }
      else {
	txCountPages = 1;
	// byteOffset set in readDone handler
      }
    }

    
    else if (((startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) == 0) &&
	     ((stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) == 0)) {
      state = READING;
      overlapStartPage = FALSE;
      overlapEndPage = FALSE;
      if (FAIL == (call EEPROMRead.read(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, dataReadBuffer))) {
	state = IDLE;
	return FAIL;
      }
      else {
	txCountPages = 1;
	byteOffset = TOS_EEPROM_LINE_SIZE;
      }
    }
    else if ((startAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) == 0) {
      state = READING;
      overlapStartPage = FALSE;
      overlapEndPage = TRUE;
      if (FAIL == (call EEPROMRead.read(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, dataReadBuffer))) {
	state = IDLE;
	return FAIL;
      }
      else {
	txCountPages = 1;
	byteOffset = TOS_EEPROM_LINE_SIZE;
      }
    }
    else if ((stopAddr & TOS_EEPROM_BYTE_ADDR_BYTE_MASK) == 0) {
      state = READING_START_PAGE;
      overlapStartPage = TRUE;
      overlapEndPage = FALSE;
      if (FAIL == (call EEPROMRead.read(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, startPageBuffer))) {
	state = IDLE;
	return FAIL;
      }
      else {
	txCountPages = 1;
	// byteOffset set in readDone handler
      }
      
      
    }
    else {
      state = READING_START_PAGE;
      overlapStartPage = TRUE;
      overlapEndPage = TRUE;
      if (FAIL == (call EEPROMRead.read(startAddr >> TOS_EEPROM_LOG2_LINE_SIZE, startPageBuffer))) {
	state = IDLE;
	return FAIL;
      }
      else {
	txCountPages = 1;
	// set byteOffset in readDone handler
      }
      
      
    }
    return SUCCESS;
    
    
  }
  
  
  
  command result_t StdControl.init() {
    if (!initialized) {
      if (FAIL == call EEPROMStdControl.init())
	return FAIL;
      maxBytes = TOS_EEPROM_MAX_LINES << TOS_EEPROM_LOG2_LINE_SIZE;
      count = 0;
      
      allocatedHead = NULL;
      allocatedTail = NULL;

      requestWithAddrHead = NULL;
      requestWithAddrTail = NULL;
      requestHead = NULL;
      requestTail = NULL;
      state = IDLE;
      initialized = TRUE;
    }
    return SUCCESS;
  }
  
  void addAllocatedRegion(RegionSpecifier* currentRequest, RegionSpecifier* allocatedRegion) {
    
    if (NULL != allocatedRegion) {
      if (allocatedRegion == allocatedHead) {
	currentRequest->prev = NULL;
	allocatedHead = currentRequest;
      }
      else {
	(allocatedRegion->prev)->next = currentRequest;
	currentRequest->prev = allocatedRegion->prev;
      }
      currentRequest->next = allocatedRegion;
      allocatedRegion->prev = currentRequest;
    }
    else {
      if (allocatedHead == NULL) {
	allocatedHead = currentRequest;
	allocatedTail = currentRequest;
	currentRequest->next = NULL;
	currentRequest->prev = NULL;
	
      }
      else {
	allocatedTail->next = currentRequest;
	currentRequest->prev = allocatedTail;
	currentRequest->next = NULL;
	allocatedTail = currentRequest;
      }
    }
  }
  
  result_t findFreeRegionAddrAndAlloc(RegionSpecifier* currentRequest) {
    RegionSpecifier* allocatedRegion = allocatedHead;
    uint32_t startByte = 0;
    uint32_t stopByte;

    while (NULL != allocatedRegion) {
      stopByte = allocatedRegion->startByte;

      if (((currentRequest->startByte >= startByte) &&
	   (currentRequest->startByte < stopByte)) &&
	  ((currentRequest->stopByte >= startByte) &&
	   (currentRequest->stopByte <= stopByte))) {

	currentRequest->id = count++;
	currentRequest->allocated = TRUE;
	
	addAllocatedRegion(currentRequest, allocatedRegion);
	
	return SUCCESS;
      }

      startByte = allocatedRegion->stopByte;
      allocatedRegion = allocatedRegion->next;
    }
    
    stopByte = maxBytes;

    
    if (((currentRequest->startByte >= startByte) &&
	 (currentRequest->startByte < stopByte)) &&
	((currentRequest->stopByte >= startByte) &&
	 (currentRequest->stopByte <= stopByte))) {
      currentRequest->id = count++;
      currentRequest->allocated = TRUE;
      addAllocatedRegion(currentRequest, allocatedRegion);
      

      
      return SUCCESS;
    }
    return FAIL;
  }
  
  // currentRequest->stopByte corresponds to the number of bytes that
  // needs to be allocated
  result_t findFreeRegionAndAlloc(RegionSpecifier* currentRequest) {
    RegionSpecifier* allocatedRegion = allocatedHead;
    uint32_t startByte = 0;
    uint32_t stopByte;
    
    while (NULL != allocatedRegion) {
      stopByte = allocatedRegion->startByte;

      if ((stopByte - startByte) >= currentRequest->stopByte) {
	currentRequest->id = count++;
	currentRequest->startByte = startByte;
	currentRequest->stopByte = startByte + currentRequest->stopByte;
	currentRequest->allocated = TRUE;

	addAllocatedRegion(currentRequest, allocatedRegion);

	return SUCCESS;
      }
      
      startByte = allocatedRegion->stopByte;
      allocatedRegion = allocatedRegion->next;
    }

    stopByte = maxBytes;

    if ((stopByte - startByte) >= currentRequest->stopByte) {
      currentRequest->id = count++;
      currentRequest->startByte = startByte;
      currentRequest->stopByte = startByte + currentRequest->stopByte;
      currentRequest->allocated = TRUE;

      addAllocatedRegion(currentRequest, allocatedRegion);

      return SUCCESS;
    }
    return FAIL;
  }

  command result_t StdControl.start() {
    uint8_t currentID;
    result_t success;
    RegionSpecifier* nextRequest;
    
    RegionSpecifier* currentRequest;
    if (!allocated) {
      call EEPROMStdControl.start();
      
      //process the requests that specified an address first
      currentRequest = requestWithAddrHead;
      while (NULL != currentRequest) {
	
	currentID = currentRequest->id;
	nextRequest = currentRequest->next;
	success = findFreeRegionAddrAndAlloc(currentRequest);
	signal AllocationReq.requestProcessed[currentID](currentRequest->id, success);
	currentRequest = nextRequest;
      }
      
      //process the requests that didn't specify an address
      currentRequest = requestHead;
      while (NULL != currentRequest) {
	currentID = currentRequest->id;
	nextRequest = currentRequest->next;
	success = findFreeRegionAndAlloc(currentRequest);
	signal AllocationReq.requestProcessed[currentID](currentRequest->id, success);
	currentRequest = nextRequest;
      }
      allocated = TRUE;
    }
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    call EEPROMStdControl.stop();
    return SUCCESS;
  }
  
  //allocate's id field represents different values at different times. Before memory is allocated, id corresponds to
  //the id of the caller's AllocateReq interface. Upon allocation, allocate's id corresponds to the id of the
  //mapped region of memory...no longer application related

  command result_t AllocationReq.request[uint8_t id](RegionSpecifier* allocate, uint32_t numBytesReq) {
    if (!(numBytesReq > 0)) {
      return FAIL;
    }
    

    //a byte address was not specified (allocate->startByte == 0xffffffff), store the number of bytes requested in stopBytes
    allocate->startByte = 0xffffffff;
    allocate->stopByte = numBytesReq;

    allocate->allocated = FALSE;
    allocate->prev = NULL;
    allocate->next = NULL;
    allocate->id = id;
    
    if ((requestHead == NULL) && (requestTail == NULL)) {
      requestHead = allocate;
    }
    else {
      requestTail->next = allocate;
    }
    requestTail = allocate;

    return SUCCESS;
    
  }  

  command result_t AllocationReq.requestAddr[uint8_t id](RegionSpecifier* allocate, uint32_t byteAddr, uint32_t numBytesReq) {
    if (!(numBytesReq > 0)) {
      return FAIL;
    }


    allocate->startByte = byteAddr;
    allocate->stopByte = byteAddr + numBytesReq;

    allocate->allocated = FALSE;
    allocate->prev = NULL;
    allocate->next = NULL;
    allocate->id = id;
    
    if ((requestWithAddrHead == NULL) && (requestWithAddrTail == NULL)) {
      requestWithAddrHead = allocate;
    }
    else {
      requestWithAddrTail->next = allocate;
    }
    requestWithAddrTail = allocate;
    
    return SUCCESS;
    
  }
  
  default event result_t AllocationReq.requestProcessed[uint8_t id](uint8_t mappedID, result_t success) {
    return SUCCESS;
  }
      
  default event result_t WriteDataToMapped.writeDone[uint8_t id](uint8_t mappedID, uint8_t* data, uint32_t numBytesWrite, result_t success) {
    return SUCCESS;
  }

  default event result_t ReadDataToMapped.readDone[uint8_t id](uint8_t mappedID, uint8_t* buffer, uint32_t numBytesRead, result_t success) {
    return SUCCESS;
  }
   
  

}

