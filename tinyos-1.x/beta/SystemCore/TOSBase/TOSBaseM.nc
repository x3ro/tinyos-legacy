// $Id: TOSBaseM.nc,v 1.6 2004/09/20 21:59:29 gtolle Exp $

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
 * Author:	Phil Buonadonna
 * Revision:	$Id: TOSBaseM.nc,v 1.6 2004/09/20 21:59:29 gtolle Exp $
 *
 *
 */
  
/* TOSBaseM
   - captures all the packets that it can hear and report it back to the UART
   - forward all incoming UART messages out to the radio
*/

/**
 * @author Phil Buonadonna
 */


module TOSBaseM {
  provides interface StdControl;
  uses {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;
    interface TokenReceiveMsg as UARTTokenReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;
    interface MacControl;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
    command result_t SetListeningMode(uint8_t power);
    command uint8_t GetListeningMode();
    interface CC1000Control;
#endif

    interface Leds;
  }
}
implementation
{
  enum {
    QUEUE_SIZE = 5
  };

  enum {
    TXFLAG_BUSY = 0x1,
    TXFLAG_TOKEN = 0x2
  };


  TOS_Msg gRxBufPool[QUEUE_SIZE]; 
  TOS_MsgPtr gRxBufPoolTbl[QUEUE_SIZE];
  uint8_t gRxHeadIndex,gRxTailIndex;

  TOS_Msg    gTxBuf;
  TOS_MsgPtr gpTxMsg;
  uint8_t    gTxPendingToken;
  uint8_t    gfTxFlags;
  
  TOS_Msg    gPingBuf;

  task void RadioRcvdTask() {
    TOS_MsgPtr pMsg;
    result_t   Result;

    dbg (DBG_USR1, "TOSBase forwarding Radio packet to UART\n");
    atomic {
      pMsg = gRxBufPoolTbl[gRxTailIndex];
      gRxTailIndex++; gRxTailIndex %= QUEUE_SIZE;
    }
    Result = call UARTSend.send(pMsg);
    if (Result != SUCCESS) {
      call Leds.yellowToggle();
      pMsg->length = 0;
    }
    else {
      call Leds.greenToggle();
    }
  }

  task void UARTRcvdTask() {
    result_t Result;

    dbg (DBG_USR1, "TOSBase forwarding UART packet to Radio\n");
    gpTxMsg->group = TOS_AM_GROUP;
    Result = call RadioSend.send(gpTxMsg);

    if (Result != SUCCESS) {
      atomic gfTxFlags = 0;
    }
    else {
      call Leds.redToggle();
    }
  }

  task void SendAckTask() {
     call UARTTokenReceive.ReflectToken(gTxPendingToken);
//     call Leds.greenToggle();
     atomic {
       gpTxMsg->length = 0;
       gfTxFlags = 0;
     }
  } 

  command result_t StdControl.init() {
    result_t ok1, ok2, ok3;
    uint8_t i;

    for (i = 0; i < QUEUE_SIZE; i++) {
      gRxBufPool[i].length = 0;
      gRxBufPoolTbl[i] = &gRxBufPool[i];
    }
    gRxHeadIndex = 0;
    gRxTailIndex = 0;

    gTxBuf.length = 0;
    gpTxMsg = &gTxBuf;
    gfTxFlags = 0;

    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();
    ok3 = call Leds.init();

    dbg(DBG_BOOT, "TOSBase initialized\n");

    atomic call MacControl.enableAck();

    return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.start() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();

    return rcombine(ok1, ok2);
  }

  command result_t StdControl.stop() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.stop();
    ok2 = call RadioControl.stop();

    return rcombine(ok1, ok2);
  }

  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr Msg) {
    TOS_MsgPtr pBuf;

    dbg(DBG_USR1, "TOSBase received radio packet.\n");

    if (Msg->crc) {

      atomic {
	pBuf = gRxBufPoolTbl[gRxHeadIndex];
	if (pBuf->length == 0) {
	  gRxBufPoolTbl[gRxHeadIndex] = Msg;
	  gRxHeadIndex++; gRxHeadIndex %= QUEUE_SIZE;
	}
	else {
	  pBuf = NULL;
	}
      }
      
      if (pBuf) {
	post RadioRcvdTask();
      }
      else {
	pBuf = Msg;
      }
    }
    else {
      pBuf = Msg;
    }

    return pBuf;
  }

  void processCommandMsg(TOS_MsgPtr Msg) {
    TOSBaseCmdMsg *cmdMsg = (TOSBaseCmdMsg*) &Msg->data;

    if (cmdMsg->addrChanged) {
      atomic TOS_LOCAL_ADDRESS = cmdMsg->addr;
    }
    if (cmdMsg->groupChanged) {
      atomic TOS_AM_GROUP = cmdMsg->group;
    }

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)    
    if (cmdMsg->rfPowerChanged) {
      call CC1000Control.SetRFPower(cmdMsg->rfPower);
    }
    if (cmdMsg->lplModeChanged) {
      atomic call SetListeningMode(cmdMsg->lplMode);
    }

    if (cmdMsg->llAckChanged) {
      if (cmdMsg->llAck == 1) {
	atomic call MacControl.enableAck();
      } else {
	atomic call MacControl.disableAck();
      }
    }
#endif
  }
  
  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr Msg) {
    TOS_MsgPtr  pBuf;

    dbg(DBG_USR1, "TOSBase received UART packet.\n");

    atomic {
      if (gfTxFlags & TXFLAG_BUSY) {
        pBuf = NULL;
      }
      else {
        pBuf = gpTxMsg;
        gfTxFlags |= (TXFLAG_BUSY);
        gpTxMsg = Msg;
      }
    }

    if (pBuf == NULL) {
      pBuf = Msg; 
    }
    else {
      post UARTRcvdTask();
    }

    return pBuf;

  }

  event TOS_MsgPtr UARTTokenReceive.receive(TOS_MsgPtr Msg, uint8_t Token) {
    TOS_MsgPtr  pBuf;
    
    dbg(DBG_USR1, "TOSBase received UART token packet.\n");

    if (Msg->type == AM_TOSBASECMDMSG) {
      processCommandMsg(Msg);
      gTxPendingToken = Token;
      post SendAckTask();
      return Msg;
    }

    atomic {
      if (gfTxFlags & TXFLAG_BUSY) {
        pBuf = NULL;
      }
      else {
        pBuf = gpTxMsg;
        gfTxFlags |= (TXFLAG_BUSY | TXFLAG_TOKEN);
        gpTxMsg = Msg;
        gTxPendingToken = Token;
      }
    }

    if (pBuf == NULL) {
      pBuf = Msg; 
    }
    else {

      post UARTRcvdTask();
    }

    return pBuf;
  }
  
  event result_t UARTSend.sendDone(TOS_MsgPtr Msg, result_t success) {
    Msg->length = 0;
    return SUCCESS;
  }
  
  event result_t RadioSend.sendDone(TOS_MsgPtr Msg, result_t success) {


    if ((gfTxFlags & TXFLAG_TOKEN)) {
      if (success == SUCCESS) {
        
        post SendAckTask();
      }
    }
    else {
      atomic {
        gpTxMsg->length = 0;
        gfTxFlags = 0;
      }
    }
    return SUCCESS;
  }
}  
