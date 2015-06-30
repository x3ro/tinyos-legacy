/* ex: set tabstop=2 shiftwidth=2 expandtab syn=c:*/
/* $Id: FilterLocalCommM.nc,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $ */

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

includes AM;

module FilterLocalCommM {
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

  command result_t StdControl.init()  {
    return call BottomStdControl.init();
  }

  command result_t StdControl.start()  {
    return call BottomStdControl.start();
  }

  command result_t StdControl.stop()  {
    return call BottomStdControl.stop();
  }
  
  command result_t SendMsg.send[ uint8_t am ]( uint16_t addr, uint8_t length, TOS_MsgPtr msg )  {
    return call BottomSendMsg.send[ am ]( addr, length, msg );
  }

  event result_t BottomSendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )  {
    dbg(DBG_TEMP,"FilterLocalCommM$sendDone: result:%d\n",success);
    return signal SendMsg.sendDone[ am ]( msg, success );
  }

  //This is the only thing this module does: it filters messages which are not
  //for this node, in case the GenericComm being used is
  //GenericCommPromiscuous

  event TOS_MsgPtr BottomReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )  {
    if (msg->addr == TOS_LOCAL_ADDRESS || msg->addr == TOS_BCAST_ADDR) {
      dbg(DBG_USR1,"FilterLocalCommM: addr:%d. Receive.\n",msg->addr);
      return signal ReceiveMsg.receive[ am ]( msg );
    }
    dbg(DBG_USR1,"FilterLocalCommM: addr:%d. Drop.\n",msg->addr);
    return msg;
  }


  default event result_t SendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )  {
    return SUCCESS;
  }

  default event TOS_MsgPtr ReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )  {
    return msg;
  }


} //end of implementation  
