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
    S_WIDLE = 2,
    S_WRITE = 3,
    S_ENDWRITE = 4
  };

  enum { // phases
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

  enum {
    LOG2_LINES_PER_PAGE = 4
  };

  uint8_t state;
  uint8_t phase;
  uint8_t *reqBuf;
  uint8_t reqBufPtr;
  uint16_t reqLine;
  uint16_t bufferPage;
  bool clean;
  uint8_t nullBytes;
  uint8_t cmdBuf[3];
  int8_t cmdBufPtr;
  uint8_t cmd;
  uint8_t currentWriter;
  result_t writeResult;
  bool deselectRequested;

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

  void selectFlash() {
    call SlavePin.low();
    call ByteSPIControl.start();
  }

  void requestStatus() {
    phase = P_STATUS;
    selectFlash();
    nullBytes = 1;
    txByte(C_REQ_STATUS);
  }

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

  void fillBuffer() {
    bufferPage = reqLine >> LOG2_LINES_PER_PAGE;
    execCommand(C_FILL_BUFFER, reqLine);
  }

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

  void handleRequest() {
    if (state == S_ENDWRITE)
      {
	if (clean)
	  endWriteDone();
	else
	  flushBuffer();
      }
    else // S_WRITE
      {
	uint16_t reqPage = reqLine >> LOG2_LINES_PER_PAGE;

	if (reqPage == bufferPage)
	  writeLine();
	else if (clean)
	  fillBuffer();
	else
	  flushBuffer();
      }
  }

  event result_t ByteSPI.rxByte(uint8_t in) {
    dbg(DBG_LOG, "LOGGER: byte received: %02x, STATE: %02x, CMD COUNT: %d, DATA COUNT: %d \n", in, state, cmdBufPtr, reqBufPtr);
    
    if (nullBytes)
      {
	nullBytes--;
	txByte(0);
	return SUCCESS;
      }

    switch (phase)
      {
      case P_STATUS:
	if (in & 0x80) /* ready */
	  {
	    call Leds.greenOn();
	    phase = P_SEND_CMD;
	  }
	else
	  call Leds.yellowOn();
	requestDeselect();
	break;

      case P_SEND_CMD:
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
	switch (cmd)
	  {
	  case C_READ:
	    reqBuf[reqBufPtr++] = in;
	    if (reqBufPtr < TOS_EEPROM_LINE_SIZE) 
	      {
		txByte(0);
		return SUCCESS;
	      }
	    break;
	  case C_WRITE:
	    dbg(DBG_LOG, "LOGGER: Byte sent: %02x\n", reqBuf[reqBufPtr]);
	    if (reqBufPtr < TOS_EEPROM_LINE_SIZE) 
	      {
		txByte(reqBuf[reqBufPtr++]);
		return SUCCESS;
	      }
	    break;
	  case C_FILL_BUFFER: case C_FLUSH_BUFFER:
	    break;
	  }
	requestDeselect();
	break;
      }
    return SUCCESS;
  }

  event result_t SlavePin.notifyHigh() {
    if (!deselectRequested)
      return SUCCESS;
    deselectRequested = FALSE;

    // handle command completion
    switch (phase)
      {
      case P_STATUS:
	requestStatus(); /* busy wait, effectively */
	break;

      case P_SEND_CMD:
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
	    handleRequest();
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
    handleRequest();

    return SUCCESS;
  }

  command result_t EEPROMWrite.endWrite[uint8_t id]() {
    if (state != S_WIDLE || id != currentWriter)
      return FAIL;

    state = S_ENDWRITE;
    handleRequest();

    return SUCCESS;
  }
}
