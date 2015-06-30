/*
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
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
/**
 *
 * The AllocSend interface should be provided by protocols above layer
 * 2 (GenericComm/AM). For example, ad-hoc routing protocols should
 * provide this interface for sending packets.
 *
 * The goal of this interface is to free applications from
 * the allocation and management of buffers on send while 
 * unaware of the structure of the underlying packet. When an
 * application wants to send a packet, it should first call 
 * allocBuffer(), which will return a free buffer. The underlying
 * component manages the allocation and later freeing of this
 * buffer after send completes. Next the application should call
 * getBuffer(), passing the buffer returned from allocBuffer(). 
 * The underlying, component, aware of the structure of its headers 
 * and footers, returns a pointer to the area of the packet that 
 * the application can fill with data; it also provides the length 
 * of the usable region within the buffer.
 *
 * The application can then fill this region with data and send it with
 * the send() call, stating how much of the region was used.
 *
 * getBuffer(), when called, should set all protocol fields into a
 * unique and recognizable state. This way, when a buffer is passed to
 * send(), the component can distinguish between packets that are
 * being forwarded and those that are originating at the mote.
 * Therefore, getBuffer() should not be called on a packet that is
 * being forwarded (route-thru).
 *
 *
 * @author  Barbara Hohlt
 * @author  Phil Levis 
 * @date    March 2 2005
 */


includes AM;
interface AllocSend {

  /**
   * This call returns a buffer of type TOS_MsgPtr 
   * from a list of free buffers.
   *
   * @return A pointer to a free buffer, if the
   * 	free list empty returns NULL 
   */

  command TOS_MsgPtr allocBuffer();

  /**
   * This call checks if a free list of type TOS_MsgPtr 
   * has free buffers.
   *
   * @return FALSE if the free list is empty, otherwise TRUE
   */
  command bool hasFreeBuffers();

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
   * Signaled when a packet sent with send() completes and
   * after returning the message back to the free list of buffers.
   *
   * @param msg The message sent and freed.
   *
   * @param success Whether the send was successful.
   *
   * @return Should always return SUCCESS.
   */
  event result_t sendDone(TOS_MsgPtr msg, result_t success);

}
