/*
 * "Copyright (c) 2003 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Philip Levis
 * Date last modified:  6/16/03
 *
 */

includes ConfigStore;
includes AM;

module ConfigStoreTestM {

  provides interface StdControl;
  uses {
    interface StdControl as NetworkControl;
    interface ReceiveMsg as ReceiveWrite;
    interface ReceiveMsg as ReceiveRead;
    interface SendMsg;
    
    interface ConfigStoreControl;
    interface ConfigRead;
    interface ConfigWrite;
  }
}

implementation {

  enum {
    CONFIG_BOOTING,
    CONFIG_CLEAR,
    CONFIG_READY,
  };
  
  TOS_Msg msg;
  TOS_MsgPtr msgPtr;
  uint8_t state;
  bool busy;
  
  command result_t StdControl.init() {
    busy = FALSE;
    msgPtr = &msg;
    return rcombine(call NetworkControl.init(),
		    call ConfigStoreControl.init(CONFIG_REGION_SIZE));

  }

  command result_t StdControl.start() {
    return call NetworkControl.start();
  }

  command result_t StdControl.stop() {
    return call NetworkControl.stop();
  }

  event void ConfigStoreControl.initialisedNoData() {
    busy = FALSE;
    return;
  }

  event void ConfigStoreControl.initialisedDataPresent() {
    busy = FALSE;
    return;
  }

  event result_t ConfigWrite.writeFail(uint8_t* buffer) {
    dbg(DBG_USR1, "ConfigStoreTest: Write fail.\n");
    busy = FALSE;
    return SUCCESS;
  }

  event result_t ConfigWrite.writeSuccess(uint8_t* buffer) {
    dbg(DBG_USR1, "ConfigStoreTest: Write success.\n");
    busy = FALSE;
    return SUCCESS;
  }

  event result_t ConfigRead.readFail(uint8_t* buffer) {
    dbg(DBG_USR1, "ConfigStoreTest: Read fail.\n");
    busy = FALSE;
    return SUCCESS;
  }

  event result_t ConfigRead.readSuccess(uint8_t* buffer) {
    dbg(DBG_USR1, "ConfigStoreTest: Read success. Sending message.\n");
    call SendMsg.send(TOS_UART_ADDR, 28, msgPtr);
    busy = FALSE;
    return SUCCESS;
  }
  
  event TOS_MsgPtr ReceiveRead.receive(TOS_MsgPtr recvMsg) {
    if (busy) {
      dbg(DBG_USR1, "ConfigStoreTest: Received read request. Busy.\n");
      return recvMsg;
    }
    else {
      int i;
      for (i = 0; i < 29; i++) {
	msgPtr->data[i] = 0xcc;
      }
      if (call ConfigRead.read(msgPtr->data, CONFIG_REGION_SIZE)) {
	dbg(DBG_USR1, "ConfigStoreTest: Received read request. Serviced.\n");
	call SendMsg.send(TOS_UART_ADDR, 28, msgPtr);
      }
      else {
	dbg(DBG_USR1, "ConfigStoreTest: Received read request. Refused.\n");
      }
      return recvMsg;
    }
  }

  event TOS_MsgPtr ReceiveWrite.receive(TOS_MsgPtr recvMsg) {
    if (busy) {
      dbg(DBG_USR1, "ConfigStoreTest: Received write request. Busy.\n");
      return recvMsg;
    }
    else {
      TOS_MsgPtr tmp = msgPtr;
      msgPtr = recvMsg;
      if (call ConfigWrite.write(msgPtr->data, CONFIG_REGION_SIZE)) {
	busy = TRUE;
	dbg(DBG_USR1, "ConfigStoreTest: Received write request. Serviced.\n");
      }
      else {
	dbg(DBG_USR1, "ConfigStoreTest: Received write request. Refused.\n");
      }
      return tmp;
    }
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr bufPtr, result_t success) {
    busy = FALSE;
    return SUCCESS;
  }

  
}
