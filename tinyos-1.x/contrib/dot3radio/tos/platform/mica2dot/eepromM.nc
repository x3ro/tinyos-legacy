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
 * 
 */
/*
 *
 * Authors:		Rob Szewczyk, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

module eepromM {
  provides {
    interface StdControl;
    interface EEPROMRead;
    /* The identity of the writer is indicated by the id they choose when
       connecting to the EEPROMWrite interface (the usual argument is
       unique("EEPROMWRite") to guarantee a unique value for each writer) */
    interface EEPROMWrite[uint8_t id];
  }
  uses {
    interface ByteSPI;
    interface StdControl as ByteSPIControl;
    interface SlavePin;
    interface StdControl as SlavePinControl;
    interface Leds;
  }
}
implementation
{
  enum { // states
    S_IDLE = 0,
    S_READ = 1,
    S_WIDLE = 2, /* startWrite called, no write in progress */
    S_WRITE = 3,
    S_ENDWRITE = 4
  };

  enum { // phases (of command transmission) 
    P_STATUS = 1,
    P_SEND_CMD = 2,
    P_EXEC_CMD = 3,
    P_FAILED = 4
  };

  enum { // commands we're executing
    C_READ = 0xd2, // Main Memory Page Read (SPI Mode 0 or 3)
    C_WRITE = 0x84, // Buffer 1 Write
    C_FILL_BUFFER = 0x53, // Main Memory Page to Buffer 1 Transfer
    C_FLUSH_BUFFER = 0x83, // Buffer to Main Memory Page Program With Built-in Erase
    C_REQ_STATUS = 0xd7
  };

  // 256-byte pages. Normally we have 16-byte lines, so 16 lines per page
  enum {
    LOG2_LINES_PER_PAGE = 8 - TOS_EEPROM_LOG2_LINE_SIZE
  };

  uint8_t state;
  uint8_t phase;
  uint8_t *reqBuf; /* The data being read or written */
  uint8_t reqBufPtr;
  uint16_t reqLine;
  uint16_t bufferPage; /* EEPROM page currently loaded */
  bool clean;
  uint8_t nullBytes; /* Number of null bytes to send */
  uint8_t cmdBuf[3]; /* command arguments */
  int8_t cmdBufPtr;
  uint8_t cmd; /* command (C_xxx) */
  uint8_t currentWriter; /* identity of writer (who called startWrite) */
  result_t writeResult; /* FAIL if any write in a sequence fails */
  bool deselectRequested; /* deselect of EEPROM requested (needed between
			     two commands) */

  command result_t StdControl.init() {
    state = S_IDLE;
    deselectRequested = FALSE;

    // pretend we're on a clean non-existent page
    bufferPage = (TOS_EEPROM_MAX_LINES >> LOG2_LINES_PER_PAGE) + 1;
    clean = TRUE;

    return rcombine(call SlavePinControl.init(), call ByteSPIControl.init());
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /* Deselect EEPROM via SlavePin */
  void requestDeselect() {
    deselectRequested = TRUE;
    call ByteSPIControl.stop();
    call SlavePin.high();
  }

  void txByte(uint8_t data) {
    if (!call ByteSPI.txByte(data))
      {
	phase = P_FAILED;
	requestDeselect();
      }
  }    

  /* Select EEPROM via SlavePin, start a SPI transaction */
  void selectFlash() {
    call SlavePin.low();
    call ByteSPIControl.start();
  }

  /* Send a C_REQ_STATUS command */
  void requestStatus() {
    phase = P_STATUS;
    selectFlash();
    nullBytes = 1;
    txByte(C_REQ_STATUS);
  }

  /* Execute reqCmd on EEPROM line line */
  void execCommand(uint8_t reqCmd, uint16_t line) {
    // byte address, there is 8bytes per page that cannot be accessed. Will
    // use for CRC, etc.
    // command buffer is filled in reverse
    cmdBuf[0] = (line << TOS_EEPROM_LOG2_LINE_SIZE) & 0xff; // byte address
    // page (2 bytes)
    cmdBuf[1] = (line >> (7 - TOS_EEPROM_LOG2_LINE_SIZE)) & 0xfe;
    cmdBuf[2] = (line >> (15 - TOS_EEPROM_LOG2_LINE_SIZE)) & 0xff;
    cmdBufPtr = 2;
    cmd = reqCmd;

    /* We wait until the EEPROM isn't busy before actually sending the
       command */
    requestStatus();
  }

  void readLine() {
    reqBufPtr = 0;
    execCommand(C_READ, reqLine);
  }

  void writeLine() {
    clean = FALSE;
    reqBufPtr = 0;
    execCommand(C_WRITE, reqLine);
  }

  /* Load the page holding reqLine */
  void fillBuffer() {
    bufferPage = reqLine >> LOG2_LINES_PER_PAGE;
    execCommand(C_FILL_BUFFER, reqLine);
  }

  /* Flush page changes back to EEPROM */
  void flushBuffer() {
    clean = TRUE;
    execCommand(C_FLUSH_BUFFER, bufferPage << LOG2_LINES_PER_PAGE);
  }

  default event result_t EEPROMWrite.writeDone[uint8_t id](uint8_t *buffer) {
    return FAIL;
  }

  default event result_t EEPROMWrite.endWriteDone[uint8_t id](result_t result) {
    return FAIL;
  }

  void endWriteDone() {
    state = S_IDLE;
    signal EEPROMWrite.endWriteDone[currentWriter](writeResult);
  }

  void readDone(result_t success) {
    state = S_IDLE;
    signal EEPROMRead.readDone(reqBuf, success);
  }
	
  default event result_t EEPROMRead.readDone(uint8_t* buf, result_t success) {
    return SUCCESS;
  }

  // Based on current state (ENDWRITE or WRITE), figure out next action
  void handleWriteRequest() {
    if (state == S_ENDWRITE)
      {
	/* If buffer page unchanged, we're done. Otherwise flush it */
	if (clean)
	  endWriteDone();
	else
	  flushBuffer();
      }
    else // S_WRITE
      {
	uint16_t reqPage = reqLine >> LOG2_LINES_PER_PAGE;

	/* Correct page loaded. Write the line */
	if (reqPage == bufferPage)
	  writeLine();
	/* Incorrect page, but current page is clean. Load correct page */
	else if (clean)
	  fillBuffer();
	else /* Incorrect page, current page dirty. Flush current page */
	  flushBuffer();
      }
  }

  /* Previous SPI byte transmission complete, in received */
  event result_t ByteSPI.rxByte(uint8_t in) {
    dbg(DBG_LOG, "LOGGER: byte received: %02x, STATE: %02x, CMD COUNT: %d, DATA COUNT: %d \n", in, state, cmdBufPtr, reqBufPtr);
    
    /* We have some null bytes to send */
    if (nullBytes)
      {
	nullBytes--;
	txByte(0);
	return SUCCESS;
      }

    switch (phase)
      {
      case P_STATUS:
	/* We're waiting for the EEPROM to be ready */
	if (in & 0x80) /* ready */
	  {
	    call Leds.greenOn();
	    /* It's ready, send next command */
	    phase = P_SEND_CMD;
	  }
	else
	  /* It isn't ready. We'll send another status request (busy wait).
	     A better EEPROM would go to sleep here for a bit */
	  call Leds.yellowOn();
	/* Actual next command (status or pending command) will be sent in
	   notifyHigh when deselect is complete */
	requestDeselect();
	break;

      case P_SEND_CMD:
	/* Send next command argument byte */
	txByte(cmdBuf[cmdBufPtr--]);
	if (cmdBufPtr < 0 && phase != P_FAILED)
	  {
	    // add necessary padding
	    if (cmd == C_READ)
	      nullBytes = 5;
	    else
	      nullBytes = 0;

	    phase = P_EXEC_CMD;
	  }
	break;

      case P_EXEC_CMD:
	/* Data to/from command */
	switch (cmd)
	  {
	  case C_READ:
	    reqBuf[reqBufPtr++] = in;
	    if (reqBufPtr < TOS_EEPROM_LINE_SIZE) 
	      {
		/* read next byte */
		txByte(0);
		return SUCCESS;
	      }
	    break;
	  case C_WRITE:
	    dbg(DBG_LOG, "LOGGER: Byte sent: %02x\n", reqBuf[reqBufPtr]);
	    if (reqBufPtr < TOS_EEPROM_LINE_SIZE) 
	      {
		/* write next byte */
		txByte(reqBuf[reqBufPtr++]);
		return SUCCESS;
	      }
	    break;
	  case C_FILL_BUFFER: case C_FLUSH_BUFFER:
	    break;
	  }
	/* Complete command. */
	requestDeselect();
	break;
      }
    return SUCCESS;
  }

  event result_t SlavePin.notifyHigh() {
    /* notifyHigh gets called when other SlavePin users do things - 
       ignore it if we're not doing anything */
    if (!deselectRequested)
      return SUCCESS;
    deselectRequested = FALSE;

    // handle command completion
    switch (phase)
      {
      case P_STATUS:
	/* request status again (busy wait) */
	requestStatus();
	break;

      case P_SEND_CMD:
	/* Start new command */
	selectFlash();
	txByte(cmd);
	break;

      case P_FAILED:
	switch (state)
	  {
	  case S_READ:
	    readDone(FAIL);
	    break;
	  case S_ENDWRITE:
	    writeResult = FAIL;
	    endWriteDone();
	    break;
	  case S_WRITE:
	    writeResult = FAIL;
	    break;
	  }
	break;

      case P_EXEC_CMD:
	/* command completed */
	switch (cmd) 
	  {
	  case C_READ:
	    readDone(SUCCESS);
	    break;
	  case C_WRITE:
	    state = S_WIDLE;
	    signal EEPROMWrite.writeDone[currentWriter](reqBuf);
	    break;
	  case C_FLUSH_BUFFER: case C_FILL_BUFFER:
	    /* continue with write/endwrite execution */
	    handleWriteRequest();
	    break;
	  }
	break;
      }
    return 0;
  }

  command result_t EEPROMRead.read(uint16_t line, uint8_t *buffer) {
    if (state != S_IDLE)
      return FAIL;
    state = S_READ;
    reqBuf = buffer;
    reqLine = line;
    readLine();
    
    return SUCCESS;
  }

  command result_t EEPROMWrite.startWrite[uint8_t id]() {
    if (state != S_IDLE)
      return FAIL;
    state = S_WIDLE;
    writeResult = SUCCESS;
    currentWriter = id;

    return SUCCESS;
  }

  command result_t EEPROMWrite.write[uint8_t id](uint16_t line, uint8_t *buffer) {
    if (state != S_WIDLE || id != currentWriter)
      return FAIL;

    state = S_WRITE;
    reqBuf = buffer;
    reqLine = line;
    handleWriteRequest();

    return SUCCESS;
  }

  command result_t EEPROMWrite.endWrite[uint8_t id]() {
    if (state != S_WIDLE || id != currentWriter)
      return FAIL;

    state = S_ENDWRITE;
    handleWriteRequest();

    return SUCCESS;
  }
}
