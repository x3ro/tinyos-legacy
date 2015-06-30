/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
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
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:	Mark Yarvis, York Liu
 *
 */

module FramedNoCRCPacketM {
   provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface ByteComm as SubByteComm;
   }
   uses {
    interface StdControl as SubControl;
    interface BareSendMsg as SubSend;
    interface ReceiveMsg as SubReceive;
    interface ByteComm;
    interface Leds;
   }
}

implementation
{
  enum {
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
     FRAME_SIZE = 4,
     PREAMBLE_SIZE = 5   // write the preamble, but don't read it
#else
     FRAME_SIZE = 4,
     PREAMBLE_SIZE = 0
#endif
  };

  uint8_t txCount;
  uint8_t txLength;
  bool subIsSending;

  uint8_t frameBytesToRead;
  uint8_t dataBytesToRead;
  uint8_t dataBytesToDeliver;

  uint8_t frameHeader[FRAME_SIZE + PREAMBLE_SIZE];

  TOS_MsgPtr msgPtr;

  command result_t Control.init() {
     atomic {
        txCount = FRAME_SIZE + PREAMBLE_SIZE;
        txLength = FRAME_SIZE + PREAMBLE_SIZE;
        subIsSending = FALSE;

        frameBytesToRead = FRAME_SIZE;
        dataBytesToRead = 0;
        dataBytesToDeliver = 0;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
        frameHeader[0] = 0xFF;  // start of preamble
        frameHeader[1] = 0x00;  // (send preamble, but don't read it
        frameHeader[2] = 0xFF;
        frameHeader[3] = 0x00;
        frameHeader[4] = 0xFF;  // end of preamble
        frameHeader[5] = 0x97;
        frameHeader[6] = 0x53; 
        frameHeader[7] = 0x71;
        frameHeader[8] = DATA_LENGTH + 7;   // 7 is TOS_Header & CRC
#else
        // no preamble
        frameHeader[0] = 0x97;
        frameHeader[1] = 0x53; 
        frameHeader[2] = 0x71;
        frameHeader[3] = DATA_LENGTH + 7;   // 7 is TOS_Header & CRC
#endif

        msgPtr = NULL;
     }

     return call SubControl.init();
  }

  command result_t Control.start() {
      return call SubControl.start();
  }

  command result_t Control.stop() {
      return call SubControl.stop();
  }

  void signalSendDone(TOS_MsgPtr msg, result_t success) {
     atomic {
        if (msg == msgPtr) {
           msgPtr = NULL;
           subIsSending = FALSE;
        }
     }
     signal Send.sendDone(msg, success);
  }

  task void signalFailure() {
      TOS_MsgPtr msg;

      atomic {
         msg = msgPtr;
      }
      signalSendDone(msg, FAIL);
  }

  command result_t Send.send(TOS_MsgPtr msg) {
     TOS_MsgPtr oldMsg;
  
     atomic {
        oldMsg = msgPtr;
        if (oldMsg == NULL) {
           msgPtr = msg;
           txCount = 1;
        }
     }

     if (oldMsg != NULL) {
        return FAIL;
     }

     if (call ByteComm.txByte(frameHeader[0]) != SUCCESS) {
        post signalFailure();
     }

     return SUCCESS;
  }

  task void callSend() {
     if (call SubSend.send(msgPtr) != SUCCESS) {
        post signalFailure();
     }
  }

  async event result_t ByteComm.txByteReady(bool success) {
     bool postFailure = FALSE;
     bool txNext = FALSE;
     uint8_t oldCount = 0;
     bool postSend = FALSE;
     bool signalReady = FALSE;

     atomic {

       if (txCount < txLength) {
	 if (success == FAIL) {
	   postFailure = TRUE;
	 } else {
	       txNext = TRUE;
	       oldCount = txCount;
	       txCount++;
	 }
       } else if ((msgPtr != NULL) && (!subIsSending)) {
	 if (success == FAIL) {
	   postFailure = TRUE;
	 }else{
	   subIsSending = TRUE;
	   postSend = TRUE;
	 }
       } else {
	 signalReady = TRUE;
       }
     }

     if (txNext) {
        if (call ByteComm.txByte(frameHeader[oldCount]) != SUCCESS) {
           postFailure = TRUE;
        }
     } else if (postSend) {
        post callSend();
     } else if (signalReady) {
        return signal SubByteComm.txByteReady(success);
     }

     if (postFailure) {
        post signalFailure();
     }

     return SUCCESS;
  }

  async event result_t ByteComm.rxByteReady(uint8_t data, bool error, 
                                            uint16_t strength) {
     uint8_t signalSubCount = 0;
     result_t ret = SUCCESS;
     uint8_t i;

     atomic {
        if (error == TRUE) {
           frameBytesToRead = FRAME_SIZE;
           signalSubCount = 1;
        } else if (frameBytesToRead > 1) {
           // keep restarting if this isn't a proper frame start
           if (data != frameHeader[FRAME_SIZE + PREAMBLE_SIZE 
                                           - frameBytesToRead]) {
              frameBytesToRead = FRAME_SIZE;
           } else {
              frameBytesToRead--;
           }
        } else if (frameBytesToRead == 1) {  // the last byte the the packet
           dataBytesToRead = data;
           // HACK: currently assumes all message types are the same length!
           dataBytesToDeliver = TOS_MsgLength(0);
           frameBytesToRead=0;
        } else if (frameBytesToRead == 0) {  // read the data
           if (dataBytesToRead <= 1) {      // last byte
              frameBytesToRead=FRAME_SIZE;  // next time, look for a frame
              signalSubCount=dataBytesToDeliver;  // pad to fill expected bytes
           } else {
              if (dataBytesToDeliver == 0) {
                 signalSubCount = 0;  // chop packets that are longer than expected
              } else {
                 signalSubCount = 1;
              }
           }
           dataBytesToRead--;
           dataBytesToDeliver--;
        }
     }

     for (i=0; i<signalSubCount; i++) {
        ret = signal SubByteComm.rxByteReady(data, error, strength);
        data = 0;   // pad with 0
     }

     return ret;
  }

  async command result_t SubByteComm.txByte(uint8_t data) {
     return call ByteComm.txByte(data);
  }

  async event result_t ByteComm.txDone() {
     bool oldSending;
     atomic {
        oldSending = subIsSending;
     }

     if (oldSending) {
        return signal SubByteComm.txDone();
     } else {
        return SUCCESS;
     }
  }

  default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
     return FAIL;
  }

  event result_t SubSend.sendDone(TOS_MsgPtr msg, result_t success) {
     signalSendDone(msg, success);
     return SUCCESS;
  }

  default event TOS_MsgPtr Receive.receive(TOS_MsgPtr m) {
      return m;
  }

  event TOS_MsgPtr SubReceive.receive(TOS_MsgPtr m) {
     return signal Receive.receive(m);
  }

}
