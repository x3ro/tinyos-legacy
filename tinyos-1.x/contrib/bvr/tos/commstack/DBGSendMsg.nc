/* ex: set tabstop=2 shiftwidth=2 expandtab syn=c:*/
/* $Id: DBGSendMsg.nc,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $ */

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

/* This should only be used as a provider of BareSendMsg on 
 * TOSSIM, because send always returns false, and the only action
 * is that the packet is printed via a number of debug messages
 */

module DBGSendMsg {
  provides interface BareSendMsg as Send;
  provides interface StdControl as Control;
}

implementation {
  
  int _DBG_MODE = DBG_USR3;

  bool busy = FALSE;
  TOS_MsgPtr msg_ptr;
 
  command result_t Control.init() {
    return SUCCESS;
  }

  command result_t Control.start() {
    return SUCCESS;
  } 

  command result_t Control.stop() {
    return SUCCESS;
  }

  command result_t Send.send(TOS_MsgPtr msg) {
    uint8_t i;
    uint8_t h = offsetof(TOS_Msg,data) + msg->length;
    dbg(DBG_USR2,"DBGSendMsg$send: %p\n",msg);
    //dbg_clear(_DBG_MODE,"UL: %d %d ",TOS_LOCAL_ADDRESS,tos_state.tos_time / 4000);
    dbg_clear(_DBG_MODE,"%d %d ",TOS_LOCAL_ADDRESS,tos_state.tos_time / 4000);
    for(i = 0; i < h; i++) 
    	dbg_clear(_DBG_MODE, "%02hhX ", ((uint8_t *)msg)[i]);
    dbg_clear(_DBG_MODE, "\n");
    return FAIL;
  }
}
