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
 * Authors:		Philip Levis
 * Date last modified:  8/12/02
 *
 * The Send interface should be provided by all protocols above layer
 * 2 (GenericComm/AM). For example, ad-hoc routing protocols should
 * provide this interface for sending packets.
 *
 * The goal of this interface is to allow applications to take part in
 * buffer swapping (avoiding the mbuf problem) on send while being
 * unaware of the structure of the underlying packet. When an
 * application wants to send a packet, it should call getBuffer(),
 * passing the packet buffer it will use. The underlying component,
 * aware of the structure of its headers and footers, returns a
 * pointer to the area of the packet that the application can fill
 * with data; it also provides the length of the usable region within
 * the buffer.
 *
 * The application can then fill this region with data and send it with
 * the send() call, stating how much of the region was used.
 *
 * getBuffer(), when called, should set all protocol fields into a
 * unique and recognizable state. This way, when a buffer is passed to
 * send(), the component can distinguish between packets that are
 * being forwarded and those that are originating at the mote.
 * Therefore, getBuffer() should not be called on a packet that is
 * being forwarded.
 *
 */

includes AM;
interface Send {
  /**
   * Send a message buffer with a data payload of a specific length.
   * The buffer should have its protocol fields set already, either through
   * a protocol-aware component or by getBuffer().
   *
   * @param msg The buffer to send.
   *
   * @param length The length of the data buffer sent using this
   * component. This must be <= the maximum length provided by
   * getBuffer().
   *
   * @return Whether the send request was successful: SUCCESS means a
   * sendDone() event will be signaled later, FAIL means one will not.
   */
  
  command result_t send(TOS_MsgPtr msg, uint16_t length);

  /**
   * Given a TinyOS message buffer, provide a pointer to the data
   * buffer within it that an application can use as well as its
   * length. If a protocol-unaware application is sending a packet
   * with this interface, it must first call getBuffer() to get a
   * pointer to the valid data region. This allows the application to
   * send a specific buffer while not requiring knowledge of the
   * packet structure. When getBuffer() is called, protocol fields
   * should be set to note that this packet requires those fields to
   * be later filled in properly. Protocol-aware components (such as a
   * routing layer that use this interface to send) should not use
   * getBuffer(); they can have their own separate calls for getting
   * the buffer.
   *
   * @param msg The message to get the data region of.
   *
   * @param length Pointer to a field to store the length of the data region.
   *
   * @return A pointer to the data region.
   */
  
  command void* getBuffer(TOS_MsgPtr msg, uint16_t* length);


  
  /**
   * Signaled when a packet sent with send() completes.
   *
   * @param msg The message sent.
   *
   * @param success Whether the send was successful.
   *
   * @return Should always return SUCCESS.
   */
  event result_t sendDone(TOS_MsgPtr msg, result_t success);
}
