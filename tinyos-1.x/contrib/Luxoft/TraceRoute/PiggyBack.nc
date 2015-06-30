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
 * Authors:  Dmitriy Korovkin
 *           LUXOFT Inc.
 * Date:     9/15/2003
 *
 */

includes PiggyBack;
includes AM;

/**
 * Traceroute interface. It allows to gather the routing information 
 * between network nodes. Interface users have to call the gather command to 
 * gather the routing information. 
 */
interface PiggyBack 
{
  /**
   * Command starts the routing information collecting process
   * 
   * @param mag pointer to the message buffer
   *
   * @param dest - destination network node address
   *
   * @return SUCCESS if the routing information collecting process 
   *  successfully started and FAIL otherwise
   */
  command result_t gather(TOS_MsgPtr msg, uint16_t dest);

  /**
   * Command starts the backward routing information collecting process
   * 
   * @param mag pointer to the message that has to be send back to the 
   * routing information collecting process originator
   *
   * @param dest - destination network node address
   *
   * @return pointer to the message should be used instead of msg
   */
  command TOS_MsgPtr gatherBack(TOS_MsgPtr msg, uint16_t dest);
  
  /**
   * Indicates that the node received a route gathering message it 
   * initiated by gather. This event is going to be called twice. First node
   * receives the message containing route from source to destination node
   * and the second message containing reverse route.
   * 
   * @param msg pointer to the message buffer
   *
   * @param payload The payload portion of the packet for this
   * protocol layer. 
   *
   * @param payloadLen The length of the payload buffer. 
   *
   * @return The buffer to use for the next receive event.
   */
  event TOS_MsgPtr routeReady(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen);
   
  /*
   * Indicates that we have received the message and have to send it back
   * @param msg pointer to the pointer to message buffer
   *
   * @param payload The payload portion of the packet for this
   * protocol layer. 
   *
   * @param payloadLen The length of the payload buffer. 
   *
   * @return SUCCESS if we should continue and FAIL if we should not do this
   */
  event result_t getBack(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen);
    
}

//eof
