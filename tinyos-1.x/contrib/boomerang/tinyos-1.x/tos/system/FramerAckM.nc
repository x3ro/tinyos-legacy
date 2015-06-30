// $Id: FramerAckM.nc,v 1.1.1.1 2007/11/05 19:10:42 jpolastre Exp $

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
 * Revision: $Revision: 1.1.1.1 $
 * 
 */

/* FramerAckM
 *
 * This module provides a generic acknowledgement handler for framed
 * token packets from FramerM.
 */

/**
 * @author Phil Buonadonna
 */


includes AM;

module FramerAckM {

  provides {
    interface ReceiveMsg as ReceiveCombined;
  }

  uses {
    interface TokenReceiveMsg;
    interface ReceiveMsg;
  }

}

implementation {

  uint8_t gTokenBuf;

  task void SendAckTask() {
    
    call TokenReceiveMsg.ReflectToken(gTokenBuf);
  }

  event TOS_MsgPtr TokenReceiveMsg.receive(TOS_MsgPtr Msg, uint8_t token) {
    TOS_MsgPtr pBuf;
    
    gTokenBuf = token;
    
    post SendAckTask();
    
    pBuf = signal ReceiveCombined.receive(Msg);
    
    return pBuf;
  }
  
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr Msg) {
    TOS_MsgPtr pBuf;
    
    pBuf = signal ReceiveCombined.receive(Msg);
    
    return pBuf;

  }
  
}
