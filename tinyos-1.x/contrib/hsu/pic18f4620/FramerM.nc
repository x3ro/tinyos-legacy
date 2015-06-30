// $Id: FramerM.nc,v 1.1 2005/06/01 14:15:59 hjkoerber Exp $

/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/*									
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
 * Author: Phil Buonadonna
 * Revision: $Revision: 1.1 $
 * 
 */

/*
 * FramerM
 * 
 * This modules provides framing for TOS_Msg's using PPP-HDLC-like framing 
 * (see RFC 1662).  When sending, a TOS_Msg is encapsulated in an HLDC frame.
 * Receiving is similar EXCEPT that the component expects a special token byte
 * be received before the data payload. The purpose of the token is to feed back
 * an acknowledgement to the sender which serves as a crude form of flow-control.
 * This module is intended for use with the Packetizer class found in
 * tools/java/net/packet/Packetizer.java.
 * 
 */

/**
 * @author Phil Buonadonna
 */


includes AM;
includes crc;

module FramerM {

  provides {
    interface StdControl;
    interface TokenReceiveMsg;
    interface ReceiveMsg;
    interface BareSendMsg;
  }

  uses {
    interface ByteComm;
    interface StdControl as ByteControl;
  }
}

implementation {

  enum {
    HDLC_QUEUESIZE	   = 2,
    HDLC_MTU		   = (sizeof(TOS_Msg)),
    HDLC_FLAG_BYTE	   = 0x7e,
    HDLC_CTLESC_BYTE	   = 0x7d,
    PROTO_ACK              = 64,
    PROTO_PACKET_ACK       = 65,
    PROTO_PACKET_NOACK     = 66,
    PROTO_UNKNOWN          = 255
  };

  enum {
    RXSTATE_NOSYNC,
    RXSTATE_PROTO,
    RXSTATE_TOKEN,
    RXSTATE_INFO,
    RXSTATE_ESC
  };

  enum {
    TXSTATE_IDLE,
    TXSTATE_PROTO,
    TXSTATE_INFO,
    TXSTATE_ESC,
    TXSTATE_FCS1,
    TXSTATE_FCS2,
    TXSTATE_ENDFLAG,
    TXSTATE_FINISH,
    TXSTATE_ERROR
  };

  enum {
    FLAGS_TOKENPEND = 0x2,
    FLAGS_DATAPEND  = 0x4,
    FLAGS_UNKNOWN   = 0x8
  };

  TOS_Msg gMsgRcvBuf[HDLC_QUEUESIZE];

  typedef struct _MsgRcvEntry {
    uint8_t Proto;
    uint8_t Token;	// Used for sending acknowledgements
    uint16_t Length;	// Does not include 'Proto' or 'Token' fields
    TOS_MsgPtr pMsg;
  } MsgRcvEntry_t ;

  MsgRcvEntry_t gMsgRcvTbl[HDLC_QUEUESIZE];

  uint8_t * gpRxBuf;    
  uint8_t * gpTxBuf;

  uint8_t  gFlags;

  // Flags variable protects atomicity
  norace uint8_t  gTxState;
  norace uint8_t  gPrevTxState;
  norace uint8_t  gTxProto;
  norace uint16_t gTxByteCnt;
  norace uint16_t gTxLength;
  norace uint16_t gTxRunningCRC;


  uint8_t  gRxState;
  uint8_t  gRxHeadIndex;
  uint8_t  gRxTailIndex;
  uint16_t gRxByteCnt;
  
  uint16_t gRxRunningCRC;
  
  TOS_MsgPtr gpTxMsg;
  uint8_t gTxTokenBuf;
  uint8_t gTxUnknownBuf;
  norace uint8_t gTxEscByte;

  task void PacketSent();

  result_t StartTx() {
    result_t Result = SUCCESS;
    bool fInitiate = FALSE;

    atomic {
      if (gTxState == TXSTATE_IDLE) {
        if (gFlags & FLAGS_TOKENPEND) {
          gpTxBuf = (uint8_t *)&gTxTokenBuf;
          gTxProto = PROTO_ACK;
          gTxLength = sizeof(gTxTokenBuf);
          fInitiate = TRUE;
          gTxState = TXSTATE_PROTO;
        }
        else if (gFlags & FLAGS_DATAPEND) {
          gpTxBuf = (uint8_t *)gpTxMsg;
          gTxProto = PROTO_PACKET_NOACK;
          gTxLength = gpTxMsg->length + (MSG_DATA_SIZE - DATA_LENGTH - 2);
          fInitiate = TRUE;
          gTxState = TXSTATE_PROTO;
        }
        else if (gFlags & FLAGS_UNKNOWN) {
          gpTxBuf = (uint8_t *)&gTxUnknownBuf;
          gTxProto = PROTO_UNKNOWN;
          gTxLength = sizeof(gTxUnknownBuf);
          fInitiate = TRUE;
          gTxState = TXSTATE_PROTO;
        }
      }
    }
    
    if (fInitiate) {
      atomic {
        gTxRunningCRC = 0; gTxByteCnt = 0;
      }
      Result = call ByteComm.txByte(HDLC_FLAG_BYTE);
      if (Result != SUCCESS) {
        atomic gTxState = TXSTATE_ERROR;
        post PacketSent();
      }
    }
    
    return Result;
  }    
  
  task void PacketUnknown() {
    atomic {
      gFlags |= FLAGS_UNKNOWN;
    }
    
    StartTx();
  }

  task void PacketRcvd() {
    MsgRcvEntry_t *pRcv = &gMsgRcvTbl[gRxTailIndex];
    TOS_MsgPtr pBuf = pRcv->pMsg;

    // Does the rcvd frame actually have a meaningful message??
    if (pRcv->Length >= offsetof(struct TOS_Msg,data)) {

      switch (pRcv->Proto) {
      case PROTO_ACK:
        break;
      case PROTO_PACKET_ACK:
        pBuf->crc = 1;  // Easier to set here... 
	pBuf = signal TokenReceiveMsg.receive(pBuf,pRcv->Token);
	break;
      case PROTO_PACKET_NOACK:
        pBuf->crc = 1;
	pBuf = signal ReceiveMsg.receive(pBuf);
	break;
      default:
        gTxUnknownBuf = pRcv->Proto;
        post PacketUnknown();
	break;
      }
    }

    atomic {
      if (pBuf) {
	pRcv->pMsg = pBuf;
      }
      pRcv->Length = 0; 
      pRcv->Token = 0; 
      gRxTailIndex++;
      gRxTailIndex %= HDLC_QUEUESIZE;
    }
  }

  task void PacketSent() {
    result_t TxResult = SUCCESS;

    atomic {
      if (gTxState == TXSTATE_ERROR) {
	TxResult = FAIL;
        gTxState = TXSTATE_IDLE;
      }
    }
    if (gTxProto == PROTO_ACK) {
      atomic gFlags ^= FLAGS_TOKENPEND;
    }
    else{
      atomic gFlags ^= FLAGS_DATAPEND;
      signal BareSendMsg.sendDone((TOS_MsgPtr)gpTxMsg,TxResult);
      atomic gpTxMsg = NULL;
    }

    // Trigger transmission in case something else is pending
    StartTx();
  }

  void HDLCInitialize() {
    int i;
    atomic {
      for (i = 0;i < HDLC_QUEUESIZE; i++) {
        gMsgRcvTbl[i].pMsg = &gMsgRcvBuf[i];
        gMsgRcvTbl[i].Length = 0;
        gMsgRcvTbl[i].Token = 0;
      }

      gFlags= 0;
      gTxState = TXSTATE_IDLE;
      gTxByteCnt = 0;
      gTxLength = 0;
      gTxRunningCRC = 0;
      gpTxMsg = NULL;
      
      gRxState = RXSTATE_NOSYNC;
      gRxHeadIndex = 0;
      gRxTailIndex = 0;
      gRxByteCnt = 0;
      gRxRunningCRC = 0;
      gpRxBuf = (uint8_t *)gMsgRcvTbl[gRxHeadIndex].pMsg;
    }
  }

  command result_t StdControl.init() {
    HDLCInitialize();
    return call ByteControl.init();
  }

  command result_t StdControl.start() {
    HDLCInitialize();
    return call ByteControl.start();
  }
  
  command result_t StdControl.stop() {
    return call ByteControl.stop();
  }

  
  command result_t BareSendMsg.send(TOS_MsgPtr pMsg) {
    result_t Result = SUCCESS;

    atomic {
      if (!(gFlags & FLAGS_DATAPEND)) {
       gFlags |= FLAGS_DATAPEND; 
       gpTxMsg = pMsg;
       //gTxLength = pMsg->length + (MSG_DATA_SIZE - DATA_LENGTH - 2);
       //gTxProto = PROTO_PACKET_NOACK;
      }
      else {
        Result = FAIL;
      }
    }

    if (Result == SUCCESS) {
      Result = StartTx();
    }

    return Result;
  }

  command result_t TokenReceiveMsg.ReflectToken(uint8_t Token) {
    result_t Result = SUCCESS;

    atomic {
      if (!(gFlags & FLAGS_TOKENPEND)) {
        gFlags |= FLAGS_TOKENPEND;
        gTxTokenBuf = Token;
      }
      else {
        Result = FAIL;
      }
    }

    if (Result == SUCCESS) {
      Result = StartTx();
    }

    return Result;
  }

  async event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength) {

    switch (gRxState) {

    case RXSTATE_NOSYNC: 
      if ((data == HDLC_FLAG_BYTE) && (gMsgRcvTbl[gRxHeadIndex].Length == 0)) {
        gMsgRcvTbl[gRxHeadIndex].Token = 0;
	gRxByteCnt = gRxRunningCRC = 0;
        gpRxBuf = (uint8_t *)gMsgRcvTbl[gRxHeadIndex].pMsg;
    	gRxState = RXSTATE_PROTO;
      }
      break;

    case RXSTATE_PROTO:
      if (data == HDLC_FLAG_BYTE) {
        break;
      }
      gMsgRcvTbl[gRxHeadIndex].Proto = data;
      gRxRunningCRC = crcByte(gRxRunningCRC,data);
      switch (data) {
      case PROTO_PACKET_ACK:
	gRxState = RXSTATE_TOKEN;
	break;
      case PROTO_PACKET_NOACK:
	gRxState = RXSTATE_INFO;
	break;
      default:  // PROTO_ACK packets are not handled
	gRxState = RXSTATE_NOSYNC;
	break;
      }
      break;

    case RXSTATE_TOKEN:
      if (data == HDLC_FLAG_BYTE) {
        gRxState = RXSTATE_NOSYNC;
      }
      else if (data == HDLC_CTLESC_BYTE) {
        gMsgRcvTbl[gRxHeadIndex].Token = 0x20;
      }
      else {
        gMsgRcvTbl[gRxHeadIndex].Token ^= data;
        gRxRunningCRC = crcByte(gRxRunningCRC,gMsgRcvTbl[gRxHeadIndex].Token);
        gRxState = RXSTATE_INFO;
      }
      break;


    case RXSTATE_INFO:
      if (gRxByteCnt > HDLC_MTU) {
	gRxByteCnt = gRxRunningCRC = 0;
	gMsgRcvTbl[gRxHeadIndex].Length = 0;
	gMsgRcvTbl[gRxHeadIndex].Token = 0;
	gRxState = RXSTATE_NOSYNC;
      }
      else if (data == HDLC_CTLESC_BYTE) {
	gRxState = RXSTATE_ESC;
      }
      else if (data == HDLC_FLAG_BYTE) {
	if (gRxByteCnt >= 2) {
	  uint16_t usRcvdCRC = (gpRxBuf[(gRxByteCnt-1)] & 0xff);
	  usRcvdCRC = (usRcvdCRC << 8) | (gpRxBuf[(gRxByteCnt-2)] & 0xff);
	  if (usRcvdCRC == gRxRunningCRC) {
	    gMsgRcvTbl[gRxHeadIndex].Length = gRxByteCnt - 2;
	    post PacketRcvd();
	    gRxHeadIndex++; gRxHeadIndex %= HDLC_QUEUESIZE;
          }
          else {
            gMsgRcvTbl[gRxHeadIndex].Length = 0;
            gMsgRcvTbl[gRxHeadIndex].Token = 0;
          }
          if (gMsgRcvTbl[gRxHeadIndex].Length == 0) {
             gpRxBuf = (uint8_t *)gMsgRcvTbl[gRxHeadIndex].pMsg;
            gRxState = RXSTATE_PROTO;
          }
          else {
            gRxState = RXSTATE_NOSYNC;
	  }
	}
	else {
	  gMsgRcvTbl[gRxHeadIndex].Length = 0;
          gMsgRcvTbl[gRxHeadIndex].Token = 0;
	  gRxState = RXSTATE_NOSYNC;
	}
	gRxByteCnt = gRxRunningCRC = 0;
      }
      else {
	gpRxBuf[gRxByteCnt] = data;
	if (gRxByteCnt >= 2) {
	  gRxRunningCRC = crcByte(gRxRunningCRC,gpRxBuf[(gRxByteCnt-2)]);
	}
	gRxByteCnt++;
      }
      break;

    case RXSTATE_ESC:
      if (data == HDLC_FLAG_BYTE) {
	// Error case, fail and resync
	gRxByteCnt = gRxRunningCRC = 0;
	gMsgRcvTbl[gRxHeadIndex].Length = 0;
	gMsgRcvTbl[gRxHeadIndex].Token = 0;
	gRxState = RXSTATE_NOSYNC;
      }
      else {
	data = data ^ 0x20;
        gpRxBuf[gRxByteCnt] = data;
	if (gRxByteCnt >= 2) {
	  gRxRunningCRC = crcByte(gRxRunningCRC,gpRxBuf[(gRxByteCnt-2)]);
	}
	gRxByteCnt++;
	gRxState = RXSTATE_INFO;
      }
      break;

    default:
      gRxState = RXSTATE_NOSYNC;
      break;
    }

    return SUCCESS;
  }

  result_t TxArbitraryByte(uint8_t Byte) {
    if ((Byte == HDLC_FLAG_BYTE) || (Byte == HDLC_CTLESC_BYTE)) {
      atomic {
        gPrevTxState = gTxState;
        gTxState = TXSTATE_ESC;
        gTxEscByte = Byte;
      }
      Byte = HDLC_CTLESC_BYTE;
    }
    
    return call ByteComm.txByte(Byte);
  }
    
  async event result_t ByteComm.txByteReady(bool LastByteSuccess) {
    result_t TxResult = SUCCESS;
    uint8_t nextByte;

    if (LastByteSuccess != TRUE) {
      atomic gTxState = TXSTATE_ERROR;
      post PacketSent();
      return SUCCESS;
    }

    switch (gTxState) {

    case TXSTATE_PROTO:
      gTxState = TXSTATE_INFO;
      gTxRunningCRC = crcByte(gTxRunningCRC,gTxProto);
      TxResult = call ByteComm.txByte(gTxProto);
      break;
      
    case TXSTATE_INFO:
      nextByte = gpTxBuf[gTxByteCnt];
      
      gTxRunningCRC = crcByte(gTxRunningCRC,nextByte);
      gTxByteCnt++;
      if (gTxByteCnt >= gTxLength) {
	gTxState = TXSTATE_FCS1;
      }
      
      TxResult = TxArbitraryByte(nextByte);
      break;
      
    case TXSTATE_ESC:

      TxResult = call ByteComm.txByte((gTxEscByte ^ 0x20));
      gTxState = gPrevTxState;
      break;
	
    case TXSTATE_FCS1:
      nextByte = (uint8_t)(gTxRunningCRC & 0xff); // LSB
      gTxState = TXSTATE_FCS2;
      TxResult = TxArbitraryByte(nextByte);
      break;

    case TXSTATE_FCS2:
      nextByte = (uint8_t)((gTxRunningCRC >> 8) & 0xff); // MSB
      gTxState = TXSTATE_ENDFLAG;
      TxResult = TxArbitraryByte(nextByte);
      break;

    case TXSTATE_ENDFLAG:
      gTxState = TXSTATE_FINISH;
      TxResult = call ByteComm.txByte(HDLC_FLAG_BYTE);

      break;

    case TXSTATE_FINISH:
    case TXSTATE_ERROR:

    default:
      break;

    }

    if (TxResult != SUCCESS) {
      gTxState = TXSTATE_ERROR;
      post PacketSent();
    }

    return SUCCESS;
  }

  async event result_t ByteComm.txDone() {

    if (gTxState == TXSTATE_FINISH) {
      gTxState = TXSTATE_IDLE;
      post PacketSent();
    }
    
    return SUCCESS;
  }


  default event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr Msg) {
    return Msg;
  }

  default event TOS_MsgPtr TokenReceiveMsg.receive(TOS_MsgPtr Msg,uint8_t Token) {
    return Msg;
  }
}
