// $Id: UartDebuggerM.nc,v 1.1.1.1 2007/11/05 19:09:24 jpolastre Exp $

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

/**
 * UartDebuggerM.nc
 * Module to drive a Scott Edwards Electronics LCD display --
 *  see http://www.seetron.com/pdf/bpi_bpk.pdf for documentation on commands, etc.
 * Note that the mote (mica or mica2) must be connected via an old style
 * programming board (e.g. new, expensive crossbow boards don't work.)
 * @author Sam Madden, Matt Welsh
 *  
 * Instructions for using the display:
 * Parts needed:
 * a) 1 9 pin female serial connector (from Radio Shack), e.g.
 *   Radio shack part # 276-1538
 * b) 1 Enclosure:
 *   Radio shack part # 910-5035
 * c) Stranded wire
 * d) Display
 * e) Power Switch (SPST, e.g. Radio shack # 275-406)
 * f) 4 AA Batteries
 * g) AA Battery Holder, e.g.
 *    Radio shack part # 270-409
 * 
 * Instructions:
 * 
 * 1) Cut holes in the enclosure for the display, serial connector, and 
 * switch.  I put the screen on the top, the switch
 * on one side, and the serial connector on the other.  I was able to cut 
 * the whole for the display to be narrow enough
 * that I could press fit the display in and have it fit snugly without 
 * falling out.  Don't permanently affix the
 * display / switch / connector just yet. I used a Dremel tool to cut the
 * enclosure -- it's not pretty, but it works...
 * 
 * 2) Solder the positive terminal of the battery pack to one pole of the 
 * switch.
 * 
 * 3) Solder the (+5) pin of the display to the other pole of the switch
 * 
 * 4) Solder the negative terminal of the battery pack to the (GND) pin on 
 * the display
 * 
 * 5) Solder a wire between the (GND) pin of the display (or the negative 
 * battery terminal) and pin 5
 * of the serial connector.
 *   
 * 6) Solder a wire between pin 3 of the serial connector and the (SER) line 
 * of the display
 * 
 * 7) Solder another wire between pin 2 of the serial connector and the 
 * (SER) line of the display
 * 
 * 8) Press fit the display in the enclosure.  Place the batteries behind it 
 * so that they keep it from fall
 * back inside the case.  Mount the power switch and serial line.  Put 
 * batteries in the battery pack.
 * 
 * 9) Connect a serial cable to your display and a PC.  Flip the power 
 * switch so that the backlight on the
 * display lights (you may have to enable the backlight by flipping the 
 * switch on the display controller board.)
 * Configure a terminal program to 9600 bps and type -- your typing should 
 * appear on the display.
 * 
 * 10) Close up the enclosure -- you're done!
 * 
 * If you don't want to solder directly to the display, there are a number 
 * of connectors available on
 * the Scott Edwards web site -- see:
 * 
 * http://www.seetron.com/lcdcbl_1.htm
 * 
 * You could solder the PBX-CBL to a battery pack /switch as described above 
 * -- this would alleviate
 * soldering the the serial connector, although I found that I had to 
 * connect pin 2 of the connector
 * (step 7 above) to get it work with the motes.
 * 
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
  char *mString;
  char *mSavedString;
  uint8_t mOffset;
  uint8_t mLen;
  uint8_t mSavedLen;
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
  task void dequeue();

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    atomic {
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
    }
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
    atomic {
      mUartState = FALSE;
    }
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
  async command result_t Debugger.writeString(char *msg, uint8_t len) {
    uint8_t state;
    bool lineMode;

    atomic {
      state = mUartState;
      lineMode =mStartOfLineMode;
    }
    if (state == IDLE) {

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
      //mica2 is 14.7456 mhz  oscillator
      //thse numbers from atmega 128 datasheet, pg 194

      outp(0, UBRR0H);
      outp(47, UBRR0L);
      outp(0, UCSR0A);  //disable double speed
#else

      outp(25, UBRR); // Set UART to 9600 bps
#endif
      atomic {
	mString = msg;
	mOffset = 0;
	mLen = len;
      }

      if (!lineMode) {
	char *str;
	uint8_t tmpstrlen,curidx;

	atomic {
	  str = idxStr;
	  curidx = idx++;
	  mUartState = WRITING_IDX;

	}
	str[0] = 0;	
	itoa(curidx, str, 10);
	strcat(str, ":");
	tmpstrlen = strlen(str);	

	atomic {
	  idx_len =tmpstrlen;
	}
	  

      } else {
	atomic {
	  mUartState = WRITING;
	}
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
  async command result_t Debugger.writeLine(char *msg, uint8_t len) {
    uint8_t state;
    uint8_t row;
    atomic {
      state = mUartState;
    }

    if (state == IDLE) {
      atomic {
	mStartOfLineMode = TRUE; //start writing at beginning of line
	mNewLineMode = TRUE;  //clear crap at end of line
      }

      atomic {
	mSavedString = msg;
      }
      atomic {
	mSavedLen = len>VIS_WID?VIS_WID:len;
	mNumBlanks = VIS_WID - mSavedLen;
	mRow = (mRow == 0)?1:0;
	row = mRow;
      }
      call Debugger.writeString(row==0?mRow1Cmd:mRow2Cmd, 2);
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
  async command result_t Debugger.clear() {
    return call Debugger.writeString(mClearCmd, 2);
  }


  /* ---------------------------------------- HELPER ROUTINES -------------------------------------- */
  //write spaces to end of visible part of the line
  result_t clearLine() {
    atomic {
      mCol++;
   
      if (mCol >= mNumBlanks-1) {
	mUartState = DONE_BLANKING;
      } else {
	mUartState = BLANKING;
      }
    }
    if (call UART.txByte(' ') == FAIL) {
      atomic {
	mUartState = IDLE;
      }
      signal Debugger.writeDone(NULL, FAIL);
      post dequeue();
      return FAIL;
    }

    return SUCCESS;
  }

  //write data in mString to the screen
  result_t writeNextChar() {
    uint8_t state;
    char *string;
    bool moreToWrite;
    atomic {
      state = mUartState;
      string = mString;
      moreToWrite = mOffset < mLen;
    }
    if (state == WRITING_IDX) {
      char c; 

      atomic {
	c = idxStr[cur_idx];
      }

      if (call UART.txByte(c) == FAIL) {
	atomic {
	  mUartState = IDLE;
	}
	signal Debugger.writeDone(string, FAIL);
	post dequeue();
	return FAIL;
      }

      atomic {
	cur_idx++;
	if (cur_idx == idx_len) {
	  
	  mUartState = WRITING;

	  cur_idx = 0;
	}
      }
    } else if (moreToWrite) {
      char c;
      atomic {
	c = string[mOffset++];
      
	switch (c) {
	case 1:
	  
	  if (state == SKIP_NEXT)  {
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
      }

      if (call UART.txByte(c) == FAIL) {
	atomic {
	  mUartState = IDLE;
	}
	signal Debugger.writeDone(string, FAIL);
	post dequeue();
	return FAIL;
      }

    } else {
      bool lineMode,newLineMode;
      uint8_t savedLen;
      char *savedStr;
      //were we just resetting to start of line -- if so, now write 
      //some data
      atomic {
	lineMode = mStartOfLineMode;
	newLineMode = mNewLineMode;
	savedLen =mSavedLen;
	savedStr = mSavedString;
      }
      if (lineMode) {
	atomic {
	  mStartOfLineMode = FALSE;
	  mUartState = IDLE;
	}
	return call Debugger.writeString(savedStr,savedLen);
      } else if (newLineMode) { //do we need to clear to the end of the line
	atomic {
	  mNewLineMode = FALSE;
	  mCol = 0;
	}
	return clearLine();
      } else { //we're done
	atomic {
	  mUartState = IDLE;
	}
	signal Debugger.writeDone(string, SUCCESS);
	post dequeue();
      }
    }
    return SUCCESS;
  }


  async event result_t UART.rxByteReady(uint8_t data, bool error, uint16_t strength) {
    // Do nothing
    return SUCCESS;
  }

  async event result_t UART.txByteReady(bool success) {
    uint8_t state;
    char *string;
    atomic {
      state = mUartState;
      string = mString;
    }
    if (!success) {
      signal Debugger.writeDone(string, FAIL);
      atomic {
	mUartState = IDLE;
      }
      post dequeue();
    } else {
      switch (state) {
      case BLANKING:
	clearLine();
	break;
      case DONE_BLANKING:
	atomic {
	  mUartState = IDLE;
	}
	signal Debugger.writeDone(NULL, SUCCESS);
	post dequeue();
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

  async event result_t UART.txDone() {
    return SUCCESS;
  }

  default async event result_t Debugger.writeDone(char *string, result_t success) {
    //do nothing
    return SUCCESS;
  }


  result_t enqueue(DbgMsg m) {
    uint8_t slot;
    atomic {
      if (mQ.size == Q_LEN) {
	slot = mQ.end++;
      } else {
	slot = mQ.end++;
	mQ.size++;
      }
      if (mQ.end >= Q_LEN)
	mQ.end = 0;
      mQ.data[slot] = m;
    }
    return SUCCESS;
  }

  task void dequeue() {
    DbgMsg m;
    bool gotOne = TRUE;
    atomic {
      uint8_t slot = mQ.start;

      if (mQ.size != 0) { 
	if (++mQ.start == Q_LEN)
	  mQ.start = 0;
	mQ.size--;
	m = mQ.data[slot];
      } else
	gotOne = FALSE;
    }
    if (!gotOne) return;
    if (m.newLine) {
      call Debugger.writeLine(m.data, m.len);
    } else {
      call Debugger.writeString(m.data, m.len);
    }
  }

  //#endif
}


