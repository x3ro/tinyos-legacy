/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
/*									tab:4
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
 * 
 */
/*
 *
 * Authors:		Philip Levis
 * Date last modified:  8/12/02
 *
 */

module MultiHopSend {
  
  provides {
    interface StdControl as Control;
    // The interface are as parameterised by the active message id
    interface Send as Send;
  }

  uses {
    event result_t sendDone();

    interface StdControl as SubControl;
    interface RouteSelect as RouteSelect;
    interface ActiveNotify as ActiveNotify;
    interface SendMsg as SendMsg;
  }
}
implementation {

  command result_t Control.init() {
    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Initialized.\n");
    return call SubControl.init();
  }
  
  command result_t Control.start() {
        dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Started.\n");
	return call SubControl.start();
  }
  
  command result_t Control.stop() {
        dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Stopped.\n");
	return call SubControl.stop();
  }

  command uint8_t* Send.getBuffer(TOS_MsgPtr msg, uint16_t* len) {
    dbg(DBG_ROUTE, "MultiHopSend: getBuffer on message at 0x%x.\n", msg);
    *len = DATA_LENGTH;
    return (uint8_t*)msg->data;
  }

  command result_t Send.send(TOS_MsgPtr msg, uint16_t len) {
    dbg(DBG_ROUTE, "MultiHopSend: Send message at 0x%x.\n", msg);
    signal Send.sendDone(msg, FAIL);
    return FAIL;
  }

  default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return FAIL;
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return FAIL;
  }

  
  
  event void ActiveNotify.activated() {
    return;
  }

  event void ActiveNotify.deactivated() {
    return;
  }
  
}
