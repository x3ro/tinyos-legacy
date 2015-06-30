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
/*
 * File contains common inline functions
 */

// debug mode to be used for this module
#define DBG_TRACERT DBG_ROUTE

  /*
   * Function returns the rest of the message node addresses buffer
   * available 
   * Param: len - total length of the message data buffer
   */
  static inline uint16_t restLen(uint16_t len)
  {
    return len - offsetof(PiggyMsg, addresses);
  }

  /*
   * Function returns number of available node addresses
   * Param: len - total length of the message data buffer
   * Attention!!!:  Here the >> 1 is used instead if
   * / sizeof(uint16_t) == / 2
   */
  static inline uint16_t nAvail(uint16_t len)
  {
    return restLen(len) >> 1;
  }

  /*
   * Function adds the address of the current host to the array of hosts
   * Param: msg - message pointer
   * Param: len - total length of the message data buffer
   * Param: payload - (optional) pointer to the data
   */
  static inline void addMe(TOS_MsgPtr msg, uint16_t len, void* payload)
  {
    PiggyMsg* pPMsg = (payload)? (PiggyMsg*)payload: (PiggyMsg*)msg->data; 

    if (!(pPMsg->flags & MSG_FILLED) && pPMsg->idx < nAvail(len))
    {
      pPMsg->addresses[pPMsg->idx++] = TOS_LOCAL_ADDRESS;
    }
  }
//eof
