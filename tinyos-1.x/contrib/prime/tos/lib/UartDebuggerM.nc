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

/**
 * UartDebuggerM.nc
 * Module to drive a Scott Edwards Electronics LCD display --
 *  see http://www.seetron.com/pdf/bpi_bpk.pdf for documentation on commands, etc.
 * @author Sam Madden, Matt Welsh
 **/
module UartDebuggerM {
  provides {
    interface StdControl;
    interface Debugger;
  }
  uses {
    interface Leds;
    interface ByteComm as UART;
  }
}
implementation {

  #define DISPLAY_WID 40
  #define VIS_WID 20
  #define DISPLAY_HGT 2
  
  typedef enum {
    IDLE = 0,    
    SKIP_NEXT = 1,
    WRITING = 2,
    BLANKING = 3,
    DONE_BLANKING = 4,
    WRITING_IDX = 5
  } UARTState;
  
  typedef struct {
    char *data;
    uint8_t len;
    bool newLine;
  }DbgMsg;


  #define Q_LEN 4
  typedef struct {
    uint8_t size;
    uint8_t start;
    uint8_t end;
    DbgMsg data[Q_LEN];
  } Q;



  UARTState mUartState;
  bool mNewLineMode, mStartOfLineMode;
  char *mString, *mSavedString;
  uint8_t mOffset;
  uint8_t mLen, mSavedLen;
  uint8_t mNumBlanks;
  char mClearCmd[2];
  char mRow1Cmd[2];
  char mRow2Cmd[2];
  char idxStr[5];
  uint8_t idx_len;
  uint8_t cur_idx;
  uint8_t idx;

  uint8_t mRow; //current position of cursor -- starts at mRow = 0, mCol = 0
  uint8_t mCol; // assumes a DISPLAY_WID x DISPLAY_HGT buffer
  Q mQ;

 
  //the initialization string that gets written out to the display
  #define INIT_STR "\xFE\x1\xFE\xF0        TinyOS 1.x"


  //internal routines
  result_t writeNextChar();
  result_t clearLine();

  result_t enqueue(DbgMsg m);
  void dequeue();

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    mUartState = IDLE;
    mNewLineMode = FALSE;
    mStartOfLineMode = FALSE;

    mClearCmd[0] = 254; //command code
    mClearCmd[1] = 1; //magic code

    mRow1Cmd[0] = 254; //command code
    mRow1Cmd[1] = 128; //magic code

    mRow2Cmd[0] = 254; //command code
    mRow2Cmd[1] = 192; //magic code

    mRow = 0;
    mCol = 0;
    mQ.size = 0;
    mQ.start =0;
    mQ.end = 0;
    idx = 0;
    return SUCCESS;
  }

  /**
   * Start things up. Set the UART to the proper bit rate and
   *  display the initialization string.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
      //mica2 is 14.7456 mhz  oscillator
      //thse numbers from atmega 128 datasheet, pg 194
    // set the uart to 9600 bps

      outp(0, UBRR0H);
      outp(47, UBRR0L); //9600
      outp(0, UCSR0A);  //disable double speed
#else
    outp(25, UBRR); // Set UART to 9600 bps
#endif
    call Debugger.writeString(INIT_STR, strlen(INIT_STR));
    return SUCCESS;
  }

  /**
   * Halt execution of the application.
   * Reset the UART to the original bit rate
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    // Reset to 57.6 KBps
    outp(0,UBRR0H); 
    outp(15, UBRR0L);

    // Set UART double speed
    outp((1<<U2X),UCSR0A);

    //	outp(0, UBRR0H);
    //outp(12, UBRR0L);
#else
    outp(12, UBRR); //reset UART to 19200
#endif
    mUartState = FALSE;
    return SUCCESS;
  }


  /** 
   * Write the specified string onto the display.
   * Note that some display can write to locations that aren't
   * visible on the screen -- e.g. a 16x2 display with a 
   * 40x2 buffer is common.
   *   
   * Use nextLine() to ensure output is visible.
   *   
   * @param msg The msg to display
   * @param len The length of the message.
   */
  command result_t Debugger.writeString(char *msg, uint8_t len) {
    if (mUartState == IDLE) {

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
      //mica2 is 14.7456 mhz  oscillator
      //thse numbers from atmega 128 datasheet, pg 194

      outp(0, UBRR0H);
      outp(47, UBRR0L);
      outp(0, UCSR0A);  //disable double speed
#else

      outp(25, UBRR); // Set UART to 9600 bps
#endif
      mString = msg;
      mOffset = 0;
      mLen = len;

      if (!mStartOfLineMode) {
	mUartState = WRITING_IDX;
	idxStr[0] = 0;
	itoa(idx++, idxStr, 10);
	strcat(idxStr, ":");
	idx_len = strlen(idxStr);
      } else {
	mUartState = WRITING;
      }
      writeNextChar();
      return SUCCESS;
    } else {
      DbgMsg m;
      m.data = msg;
      m.len = len;
      m.newLine = FALSE;
      return enqueue(m);
    }
  }

  /** 
   * Write the specified string out to its own line on the display 
   * @see Debugger.writeString
   */
  command result_t Debugger.writeLine(char *msg, uint8_t len) {
    if (mUartState == IDLE) {
      mStartOfLineMode = TRUE; //start writing at beginning of line
      mNewLineMode = TRUE;  //clear crap at end of line
      mSavedString = msg;
      mSavedLen = len>VIS_WID?VIS_WID:len;
      mNumBlanks = VIS_WID - mSavedLen;
      mRow = (mRow == 0)?1:0;
      call Debugger.writeString(mRow==0?mRow1Cmd:mRow2Cmd, 2);
      return SUCCESS;
    } else {
      DbgMsg m;
      m.data = msg;
      m.len = len;
      m.newLine = TRUE;
      return enqueue(m);
    }
  }

  /** Clear the display */
  command result_t Debugger.clear() {
    return call Debugger.writeString(mClearCmd, 2);
  }


  /* ---------------------------------------- HELPER ROUTINES -------------------------------------- */
  //write spaces to end of visible part of the line
  result_t clearLine() {
    mCol++;
    if (mCol >= mNumBlanks-1) {
      mUartState = DONE_BLANKING;
    } else {
      mUartState = BLANKING;
    }
    if (call UART.txByte(' ') == FAIL) {
      mUartState = IDLE;
      signal Debugger.writeDone(NULL, FAIL);
      dequeue();
      return FAIL;
    }

    return SUCCESS;
  }

  //write data in mString to the screen
  result_t writeNextChar() {
    if (mUartState == WRITING_IDX) {
      char c = idxStr[cur_idx];

      if (call UART.txByte(c) == FAIL) {
	mUartState = IDLE;
	signal Debugger.writeDone(mString, FAIL);
	dequeue();
	return FAIL;
      }

      cur_idx++;
      if (cur_idx == idx_len) {
	mUartState = WRITING;
	cur_idx = 0;
      }
    } else if (mOffset < mLen) {
      char c = mString[mOffset++];
      switch (c) {
      case 1:
	if (mUartState == SKIP_NEXT)  {
	  mRow = 0;
	}
	mUartState = WRITING;
	break;
      case 254:
	mUartState = SKIP_NEXT;
	break;
      default:
	mUartState = WRITING;
      }

      if (call UART.txByte(c) == FAIL) {
	mUartState = IDLE;
	signal Debugger.writeDone(mString, FAIL);
	dequeue();
	return FAIL;
      }

    } else {
      //were we just resetting to start of line -- if so, now write 
      //some data
      if (mStartOfLineMode) {
	mStartOfLineMode = FALSE;
	mUartState = IDLE;
	return call Debugger.writeString(mSavedString,mSavedLen);
      } else if (mNewLineMode) { //do we need to clear to the end of the line
	mNewLineMode = FALSE;
	mCol = 0;
	return clearLine();
      } else { //we're done
	mUartState = IDLE;
	signal Debugger.writeDone(mString, SUCCESS);
	dequeue();
      }
    }
    return SUCCESS;
  }


  event result_t UART.rxByteReady(uint8_t data, bool error, uint16_t strength) {
    // Do nothing
    return SUCCESS;
  }

  event result_t UART.txByteReady(bool success) {
    if (!success) {
      signal Debugger.writeDone(mString, FAIL);
      mUartState = IDLE;
      dequeue();
    } else {
      switch (mUartState) {
      case BLANKING:
	clearLine();
	break;
      case DONE_BLANKING:
	mUartState = IDLE;
	signal Debugger.writeDone(NULL, SUCCESS);
	dequeue();
	break;
      case IDLE:
	break;
      default:
	writeNextChar();
	break;
      }
    }
    return SUCCESS;
  }

  event result_t UART.txDone() {
    return SUCCESS;
  }

  default event result_t Debugger.writeDone(char *string, result_t success) {
    //do nothing
    return SUCCESS;
  }


  result_t enqueue(DbgMsg m) {
    uint8_t slot;

    if (mQ.size == Q_LEN) {
      slot = mQ.end++;
    } else {
      slot = mQ.end++;
      mQ.size++;
    }
    if (mQ.end >= Q_LEN)
      mQ.end = 0;
    mQ.data[slot] = m;
    return SUCCESS;
  }

  void dequeue() {
    uint8_t slot = mQ.start;
    DbgMsg m;
    if (mQ.size == 0) { 
      return;
    }
    if (++mQ.start == Q_LEN)
      mQ.start = 0;
    mQ.size--;
    m = mQ.data[slot];
    if (m.newLine) {
      call Debugger.writeLine(m.data, m.len);
    } else {
      call Debugger.writeString(m.data, m.len);
    }
  }

  //#endif
}


