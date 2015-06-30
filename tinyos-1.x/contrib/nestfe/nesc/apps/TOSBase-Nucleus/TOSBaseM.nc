// $Id: TOSBaseM.nc,v 1.1 2005/07/28 20:36:33 gtolle Exp $

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
 * @author Phil Buonadonna
 * @author Gilman Tolle
 * Revision:	$Id: TOSBaseM.nc,v 1.1 2005/07/28 20:36:33 gtolle Exp $
 */
  
/* 
 * TOSBaseM bridges packets between a serial channel and the radio.
 * Messages moving from serial to radio will be tagged with the group
 * ID compiled into the TOSBase, and messages moving from radio to
 * serial will be filtered by that same group id.
 *
 * For manageability, TOSBaseM also provides a local communication,
 * acting as a virtual endpoint. This endpoint receives all messages
 * sent in through the UART, and all messages it sends will go to the
 * UART.  
 */

#ifndef TOSBASE_BLINK_ON_DROP
#define TOSBASE_BLINK_ON_DROP
#endif

module TOSBaseM {
  provides {
    interface StdControl;
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];
  }
  uses {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;
    interface TokenReceiveMsg as UARTTokenReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;

    interface Leds;
  }
}

implementation
{
  enum {
    UART_QUEUE_LEN = 12,
    RADIO_QUEUE_LEN = 12,
  };

  TOS_Msg    uartQueueBufs[UART_QUEUE_LEN];
  uint8_t    uartIn, uartOut;
  bool       uartBusy, uartCount;

  uint16_t   uartReceivePackets;

  uint16_t   uartSendPackets;
  uint16_t   uartDropPackets;

  void sendUart(TOS_MsgPtr Msg);

  TOS_Msg    radioQueueBufs[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioCount;

  uint16_t   radioReceivePackets;

  uint16_t   radioSendPackets;
  uint16_t   radioDropPackets;

  result_t sendRadio(TOS_MsgPtr Msg);

  TOS_MsgPtr localBufHolder;
  TOS_Msg    localBuf;
  bool       localBufBusy;

  uint16_t   localReceivePackets;
  
  uint16_t   localSendPackets;
  uint16_t   localDropPackets;

  void sendLocal(TOS_MsgPtr Msg);

  task void UARTSendTask();
  task void RadioSendTask();

  task void signalSendDone();

  void failBlink();
  void dropBlink();
  void processUartPacket(TOS_MsgPtr Msg, bool wantsAck, uint8_t Token);

  command result_t StdControl.init() {
    result_t ok1, ok2, ok3;

    uartIn = uartOut = uartCount = 0;
    uartBusy = FALSE;

    radioIn = radioOut = radioCount = 0;
    radioBusy = FALSE;

    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();
    ok3 = call Leds.init();

    dbg(DBG_BOOT, "TOSBase initialized\n");

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

  /******* RADIO LINK ********/

  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr Msg) {

    dbg(DBG_USR1, "TOSBase received radio packet.\n");

    if ((!Msg->crc) || (Msg->group != TOS_AM_GROUP))
      return Msg;

    radioReceivePackets++;
    sendLocal(Msg);
    sendUart(Msg);
    return Msg;
  }

  result_t sendRadio(TOS_MsgPtr Msg) {
    result_t result;

    if (radioCount < RADIO_QUEUE_LEN) {
      result = TRUE;
      radioSendPackets++;
      memcpy(&radioQueueBufs[radioIn], Msg, sizeof(TOS_Msg));

      radioCount++;
      
      if( ++radioIn >= RADIO_QUEUE_LEN ) radioIn = 0;
      
      if (!radioBusy) {
	if (post RadioSendTask()) {
	  radioBusy = TRUE;
	}
      }
    } else {
      result = FALSE;
      radioDropPackets++;
      dropBlink();
    }

    return result;
  }
  
  task void RadioSendTask() {

    dbg(DBG_USR1, "TOSBase forwarding UART packet to Radio\n");

    if (radioCount == 0) {

      radioBusy = FALSE;

    } else {

      radioQueueBufs[radioOut].group = TOS_AM_GROUP;
      
      if (call RadioSend.send(&radioQueueBufs[radioOut]) == SUCCESS) {
	call Leds.redToggle();
      } else {
	failBlink();
	post RadioSendTask();
      }
    }
  }

  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {

    if (!success) {
      failBlink();
    } else {
      radioCount--;
      if( ++radioOut >= RADIO_QUEUE_LEN ) radioOut = 0;
    }
    
    post RadioSendTask();
    return SUCCESS;
  }


  /******* UART LINK ********/

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr Msg) {
    processUartPacket(Msg, FALSE, 0);
    return Msg;
  }

  event TOS_MsgPtr UARTTokenReceive.receive(TOS_MsgPtr Msg, uint8_t Token) {
    processUartPacket(Msg, TRUE, Token);
    return Msg;
  }

  void processUartPacket(TOS_MsgPtr Msg, bool wantsAck, uint8_t Token) {
    result_t radioResult;
    dbg(DBG_USR1, "TOSBase received UART token packet.\n");

    uartReceivePackets++;
    radioResult = sendRadio(Msg);
    sendLocal(Msg);

    if (wantsAck && radioResult == SUCCESS) {
      call UARTTokenReceive.ReflectToken(Token);
    }
  }


  void sendUart(TOS_MsgPtr Msg) {
    if (uartCount < UART_QUEUE_LEN) {

      uartSendPackets++;

      memcpy(&uartQueueBufs[uartIn], Msg, sizeof(TOS_Msg));
      uartCount++;

      if( ++uartIn >= UART_QUEUE_LEN ) uartIn = 0;

      if (!uartBusy) {
	if (post UARTSendTask()) {
	  uartBusy = TRUE;
	}
      }
    } else {
      uartDropPackets++;
      dropBlink();
    }
  }

  task void UARTSendTask() {
    dbg (DBG_USR1, "TOSBase forwarding Radio packet to UART\n");

    if (uartCount == 0) {

      uartBusy = FALSE;

    } else {

      if (call UARTSend.send(&uartQueueBufs[uartOut]) == SUCCESS) {
	call Leds.greenToggle();
      } else {
	failBlink();
	post UARTSendTask();
      }
    }
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {

    if (!success) {
      failBlink();
    } else {
      uartCount--;
      if( ++uartOut >= UART_QUEUE_LEN ) uartOut = 0;
    }
    
    post UARTSendTask();

    return SUCCESS;
  }

  void dropBlink() {
#ifdef TOSBASE_BLINK_ON_DROP
    call Leds.yellowToggle();
#endif
  }

  void failBlink() {
#ifdef TOSBASE_BLINK_ON_FAIL
    call Leds.yellowToggle();
#endif
  }

  /******* LOCAL LINK ********/

  command result_t SendMsg.send[uint8_t id](uint16_t address, uint8_t length, 
					    TOS_MsgPtr msg) {
    if (localBufHolder != NULL) {
      return FAIL;
    }

    localReceivePackets++;

    localBufHolder = msg;
    msg->addr = address;
    msg->type = id;
    msg->length = length;
    msg->group = TOS_AM_GROUP;

    sendUart(msg);
    sendRadio(msg);

    post signalSendDone();
    return SUCCESS;
  }

  task void signalSendDone() {
    signal SendMsg.sendDone[localBufHolder->type](localBufHolder, SUCCESS);
    localBufHolder = NULL;
  }

  void sendLocal(TOS_MsgPtr Msg) {
    if (Msg->addr == TOS_LOCAL_ADDRESS || Msg->addr == TOS_BCAST_ADDR) {
      if (!localBufBusy) {
	localSendPackets++;
	memcpy(&localBuf, Msg, sizeof(TOS_Msg));
	signal ReceiveMsg.receive[localBuf.type](&localBuf);
      } else {
	localDropPackets++;
      }
    }
  }

  default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr m) {
    return m;
  }
}  
