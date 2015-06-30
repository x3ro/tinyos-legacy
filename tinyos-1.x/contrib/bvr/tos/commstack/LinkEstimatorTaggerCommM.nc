/* ex: set tabstop=2 shiftwidth=2 expandtab syn=c:*/
/* $Id: LinkEstimatorTaggerCommM.nc,v 1.2 2005/06/22 02:32:34 rfonseca76 Exp $ */

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



/* UART packets (inbound and outbound) are NOT used for link estimation */
/* Outgoing UART packets are not altered in any way */


includes AM;
includes LinkEstimator;

module LinkEstimatorTaggerCommM {
  provides {
    interface StdControl;
    interface SendMsg[ uint8_t am];
    interface ReceiveMsg[uint8_t am];
  }
  uses {
    interface StdControl as BottomStdControl;
    interface SendMsg as BottomSendMsg[ uint8_t am ];
    interface ReceiveMsg as BottomReceiveMsg[ uint8_t am ];
  }
}
implementation {
  
  uint16_t my_seqno;

  command result_t StdControl.init()  {
    my_seqno = 1;
    return call BottomStdControl.init();
  }

  command result_t StdControl.start()  {
    return call BottomStdControl.start();
  }

  command result_t StdControl.stop()  {
    return call BottomStdControl.stop();
  }

  //This is the only thing this module does, tag the outgoing packets with an ever increasing
  //sequence number and with the local address.
  //This is not subject to freezing, because we assume that it is the recipient who
  //should freeze the link quality of this node.
  command result_t SendMsg.send[ uint8_t am ]( uint16_t addr, uint8_t length, TOS_MsgPtr msg )  {
    LEHeader* link_header_ptr = (LEHeader*)&msg->data[0];
    if (addr != TOS_UART_ADDR) {
      dbg(DBG_USR1,"LinkEstimatorCommM$send. Will tag packet with sequence number (%d)\n",my_seqno);
      link_header_ptr->last_hop = TOS_LOCAL_ADDRESS;
      link_header_ptr->seqno = my_seqno++; 
    }
    return call BottomSendMsg.send[ am ]( addr, length, msg );
  }

  event result_t BottomSendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )  {
    dbg(DBG_TEMP,"LinkEstimatorCommM$sendDone: result:%d\n",success);
    return signal SendMsg.sendDone[ am ]( msg, success );
  }

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
