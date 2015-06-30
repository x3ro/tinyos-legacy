/* ex: set tabstop=2 shiftwidth=2 expandtab syn=c:*/
/* $Id: UARTInterceptCommM.nc,v 1.2 2005/06/22 02:34:27 rfonseca76 Exp $ */

/*                                                                      
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
 * Authors:  Rodrigo Fonseca
 * Date Last Modified: 2005/05/26
 */

/*
  This module will divert all messages sent to the UART to
  a separate BareSendMsg. Only wire to the PC implementation,
  using DBGSendMsg.
*/

includes AM;

module UARTInterceptCommM {
  provides {
    interface StdControl;
    interface SendMsg[ uint8_t am];
    interface ReceiveMsg[uint8_t am];
  }
  uses {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;

    interface StdControl as BottomStdControl;
    interface SendMsg as BottomSendMsg[ uint8_t am ];
    interface ReceiveMsg as BottomReceiveMsg[ uint8_t am ];

  }
}
implementation {


  command result_t StdControl.init()  {
    call UARTControl.init();
    call BottomStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()  {
    call UARTControl.start();
    return call BottomStdControl.start();
  }

  command result_t StdControl.stop()  {
    call UARTControl.stop();
    return call BottomStdControl.stop();
  }
  
  command result_t SendMsg.send[ uint8_t am ]( uint16_t addr, uint8_t length, TOS_MsgPtr msg )  {
    result_t ok;
    dbg(DBG_USR2,"UARTInterceptCommM$Send: (%p) am:%d addr:%d msg.addr:%d length:%d\n",
        msg, am, addr, msg->addr, length);
    if (addr == TOS_UART_ADDR) {
      msg->type = am;
      msg->length = length;
      msg->group = TOS_AM_GROUP;
      //Address is not set here. UARTLoggerComm should set in case of a UART packet.
      //Otherwise, we want to preserve the original destination in the UART packet,
      //instead of having it be TOS_UART_ADDRESS. This is the main point of all of this.
      ok = call UARTSend.send(msg);
      dbg(DBG_USR2,"UARTInterceptCommM$Send to UART: result:%d\n",ok);
    } else {
      ok = call BottomSendMsg.send[ am ]( addr, length, msg );
      dbg(DBG_USR2,"UARTInterceptCommM$Send to BottomSend: result:%d\n",ok);
    }
    return ok;
  }

  event result_t BottomSendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )  {
    dbg(DBG_USR2,"UARTInterceptCommM$sendDone: (%p) am:%d result:%d\n",msg,am,success);
    return signal SendMsg.sendDone[ am ]( msg, success );
  }

  //This does not do anything. 
  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  //Doesn't do anything special
  event TOS_MsgPtr BottomReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )  {
    return signal ReceiveMsg.receive[ am ]( msg );
  }


  default event result_t SendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )  {
    return SUCCESS;
  }

  default event TOS_MsgPtr ReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )  {
    return msg;
  }


} //end of implementation  
