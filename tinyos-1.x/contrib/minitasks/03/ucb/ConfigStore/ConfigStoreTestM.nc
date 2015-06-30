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
  
  uint8_t config[] = {0x01, 0x02, 0x04, 0x33,
		      0x00, 0xde, 0xad, 0xbe,
		      0xef, 0xad, 0xde, 0xfe,
		      0x71, 0x00, 0xce, 0x77,
		      0xff, 0x11, 0x22, 0x44,
		      0x88, 0xff, 0x33, 0x77,
		      0xab, 0xee, 0x55, 0xaa};
  
  TOS_Msg msg;
  TOS_MsgPtr msgPtr;
  uint8_t state;
  bool busy;
  
  command result_t StdControl.init() {
    msgPtr = &msg;
    busy = TRUE;
    call SendMsg.send(TOS_BCAST_ADDR, 0, msgPtr);
    return call NetworkControl.init();

  }

  command result_t StdControl.start() {
    return call NetworkControl.start();
  }

  command result_t StdControl.stop() {
    return call NetworkControl.stop();
  }

  task void writeTask() {
    call ConfigWrite.write(config, sizeof(config));
  }

  task void readTask() {
    call ConfigRead.read(msgPtr->data, sizeof(config));
  }

  task void failTask() {
    call SendMsg.send(TOS_BCAST_ADDR, 1, msgPtr);
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (busy) {
      call ConfigStoreControl.init(CONFIG_REGION_SIZE);
    }
    busy = FALSE; 
    return SUCCESS;
  }
  
  event void ConfigStoreControl.initializedNoData() {
    post writeTask();
    return;
  }

  event void ConfigStoreControl.initializedDataPresent() {
    post readTask();
    return;
  }

  event void ConfigWrite.writeFail(uint8_t* buffer) {
    dbg(DBG_USR1, "ConfigStoreTest: Write fail.\n");
    post failTask();
  }

  event void ConfigWrite.writeSuccess(uint8_t* buffer) {
    dbg(DBG_USR1, "ConfigStoreTest: Write success.\n");
    //post readTask();
  }

  event void ConfigRead.readFail(uint8_t* buffer) {
    dbg(DBG_USR1, "ConfigStoreTest: Read fail.\n");
    post failTask();
  }

  event void ConfigRead.readSuccess(uint8_t* buffer) {
    dbg(DBG_USR1, "ConfigStoreTest: Read success. Sending message.\n");
    call SendMsg.send(TOS_BCAST_ADDR, 28, msgPtr);
  }
  
}
