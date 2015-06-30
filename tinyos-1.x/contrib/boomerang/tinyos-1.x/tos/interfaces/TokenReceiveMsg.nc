// $Id: TokenReceiveMsg.nc,v 1.1.1.1 2007/11/05 19:09:04 jpolastre Exp $

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

/**
 * @author Phil Buonadonna
 */


includes AM;

/**
 * Receive messages with an identifying token that can be used for
 * acknowledgement.
 *
 * @author Phil Buonadonna
 */

interface TokenReceiveMsg
{

  /** 
   * A packet and an associated token have been recieved. 
   * The one-byte token is a unique value linked to the message received.
   * This interface is designed for use by modules like HDLCM which 
   * may pass a token up that is later used as part of an acknowledgement
   * process.
   *
   * @param Msg A pointer to the received TOS_Msg
   * @param Token A one byte token associated with the recieved message.
   *
   * @return A buffer for the provider to use for the next packet.
   * 
   */

  event TOS_MsgPtr receive(TOS_MsgPtr Msg, uint8_t Token);

  /**
   * Sends a one byte token down the original channel that received the token.
   * This function can be used as an acknowledgement mechanism.
   *
   * @param Token  A one byte token.
   *
   * @return SUCCESS if the provider was able to queue the token for 
   * transmission.
   *
   */

  command result_t ReflectToken(uint8_t Token);


}
