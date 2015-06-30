/* ex: set tabstop=2 shiftwidth=2 expandtab syn=c:*/
/* $Id: GenericCommReallyPromiscuousM.nc,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $ */

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

/* The sole purpose of this module is to turn on the promiscuous
   mode of GenericCommPromiscuous upon initialization, to make this
   transparent to upper layers */

includes AM;

module GenericCommReallyPromiscuousM {
  provides {
    interface StdControl;
    interface SendMsg[ uint8_t am];
    interface ReceiveMsg[uint8_t am];
  }
  uses {
    interface StdControl as BottomStdControl;
    interface SendMsg as BottomSendMsg[ uint8_t am ];
    interface ReceiveMsg as BottomReceiveMsg[ uint8_t am ];
    interface CommControl;
#if defined(PLATFORM_MICA2) || defined (PLATFORM_MICA2DOT)
    interface MacControl;
#endif
  }
}
implementation {

  command result_t StdControl.init()  {
    result_t ok1,ok2;
    ok1 = call BottomStdControl.init();
    ok2 = call CommControl.setPromiscuous(TRUE);
    return rcombine(ok1,ok2);
  }

  command result_t StdControl.start()  {
    result_t ok;
    ok = call BottomStdControl.start();
#if defined(PLATFORM_MICA2) || defined (PLATFORM_MICA2DOT)
    call MacControl.enableAck();
#endif
    return ok;
  }

  command result_t StdControl.stop()  {
    return call BottomStdControl.stop();
  }

  command result_t SendMsg.send[ uint8_t am ]( uint16_t addr, uint8_t length, TOS_MsgPtr msg )  {
    return call BottomSendMsg.send[ am ]( addr, length, msg );
  }

  event result_t BottomSendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )  {
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
