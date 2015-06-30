// $Id: BufferedLog.nc,v 1.4 2003/10/07 21:46:36 idgay Exp $

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
 * This components supports high frequency logging.  While one buffer is
 * filled by application, the other buffer is written to EEPROM as a
 * background task.
 *
 * It supports the <code>LogData</code> interface, but only allows
 * individual appends up to the buffer size (currently 128). It is 
 * expected that each append will be small (e.g., a single or small
 * group of sensor samples) 
 */
module BufferedLog {
  provides {
    interface LogData;
    async command result_t fastAppend(uint8_t *data, uint8_t n);
  }
  uses interface LogData as Logger;
}
implementation {
  enum {
    BUFSIZE = 128
  };

  // sync operation state
  enum {
    F_NONE, // not running
    F_PENDING, // waiting for internal flush to complete
    F_FLUSHING // waiting for user flush to complete
  };
  enum {
    S_WRITE,
    S_BUSY,
    S_NOWRITE
  };
  uint8_t syncState;

  norace uint8_t buffer1[BUFSIZE], buffer2[BUFSIZE];
  norace uint8_t *buffer, *toFlush;
  norace uint8_t offset, flushCount;
  norace bool flushing;
  uint8_t state = S_NOWRITE;

  task void flushBuffer() {
    call Logger.append(toFlush, flushCount);
  }

  async command result_t fastAppend(uint8_t *data, uint8_t n) {
    uint8_t *ptr;
    result_t ok = SUCCESS;
    uint8_t oops;

    // Check for reentrancy attempt
    atomic
      {
	oops = state;
	if (oops == S_WRITE)
	  state = S_BUSY;
      }
    if (oops != S_WRITE)
      return FAIL;

    if (offset + n > BUFSIZE)
      {
	if (flushing)
	  ok = FAIL;
	else
	  {
	    flushing = TRUE;
	    toFlush = buffer;
	    flushCount = offset;
	    post flushBuffer();

	    offset = 0;
	    if (buffer == buffer1)
	      buffer = buffer2;
	    else
	      buffer = buffer1;
	  }
      }

    if (ok)
      {
	ptr = buffer + offset;
	offset += n;

	while (n--)
	  *ptr++ = *data++;
      }

    atomic state = S_WRITE;

    return ok;
  }

  command result_t LogData.append(uint8_t* data, uint32_t numBytes) {
    return FAIL;
  }

  void userFlushDone();
  void systemFlushDone();

  event result_t Logger.appendDone(uint8_t* data, uint32_t numBytes,
				   result_t success) {
    switch (syncState)
      {
      case F_FLUSHING:
	userFlushDone();
	break;
      case F_PENDING:
	systemFlushDone();
	break;
      case F_NONE: // Internal flush
	atomic flushing = FALSE;
	break;
      }
    return SUCCESS;
  }

  command result_t LogData.sync() {
    bool oops;

    // User-requested flush. Note that an internal flush may already
    // be in progress, and that must not be an error...

    atomic
      {
	oops = state;
	state = S_BUSY; // prevent further fastAppends
      }

    if (oops == S_BUSY)
      return FAIL;

    if (flushing) // Wait for internal flush to complete
      syncState = F_PENDING;
    else
      systemFlushDone();

    return SUCCESS;
  }

  void systemFlushDone() {
    if (offset)
      {
	syncState = F_FLUSHING;
	call Logger.append(buffer, offset);
      }
    else
      userFlushDone();
  }

  void userFlushDone() {
    call Logger.sync();
  }

  event result_t Logger.syncDone(result_t success) {
    atomic state = S_NOWRITE;
    return signal LogData.syncDone(success);
  }

  command result_t LogData.erase() {
    bool oops;

    atomic
      {
	oops = state;
	state = S_BUSY;
      }

    if (oops == S_BUSY)
      return FAIL;

    // Start logging to 1st buffer
    buffer = buffer1;
    offset = 0;
    flushing = FALSE;
    syncState = F_NONE;

    return call Logger.erase();
  }

  event result_t Logger.eraseDone(result_t success) {
    atomic state = S_WRITE;
    return signal LogData.eraseDone(success);
  }

  command uint32_t LogData.currentOffset() {
    return call Logger.currentOffset() + offset + (flushing ? flushCount : 0);
  }
}
