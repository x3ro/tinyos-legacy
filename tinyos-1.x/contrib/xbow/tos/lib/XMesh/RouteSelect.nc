// $Id: RouteSelect.nc,v 1.2 2005/01/14 01:25:22 jdprabhu Exp $

/*
 * Copyright (c) 2005 Crossbow Technology, Inc.
 *
 * All rights reserved.
 *
 * Permission to use, copy, modify and distribute, this software and
 * documentation is granted, provided the following conditions are met:
 * 
 * 1. The above copyright notice and these conditions, along with the
 * following disclaimers, appear in all copies of the software.
 * 
 * 2. When the use, copying, modification or distribution is for COMMERCIAL
 * purposes (i.e., any use other than academic research), then the software
 * (including all modifications of the software) may be used ONLY with
 * hardware manufactured by and purchased from Crossbow Technology, unless
 * you obtain separate written permission from, and pay appropriate fees
 * to, Crossbow. For example, no right to copy and use the software on
 * non-Crossbow hardware, if the use is commercial in nature, is permitted
 * under this license. 
 *
 * 3. When the use, copying, modification or distribution is for
 * NON-COMMERCIAL PURPOSES (i.e., academic research use only), the software
 * may be used, whether or not with Crossbow hardware, without any fee to
 * Crossbow. 
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE
 * TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
 * EVEN IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM
 * ALL WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY
 * LICENSOR HAS ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS. 
 * 
 */

includes AM;
interface RouteSelect {

  /**
   * Whether there is currently a valid route.
   *
   * @return Whether there is a valid route.
   */
  command bool isActive();

  /**
   * Select a route and fill in all of the necessary routing
   * information to a packet.
   *
   * @param msg Message to select route for and fill in routing information.
   *
   * @return Whether a route was selected succesfully. On FAIL the
   * packet should not be sent.
   *
   */
  
  command result_t selectRoute(TOS_MsgPtr msg, uint8_t id, uint8_t resend, uint8_t monitor);
  command result_t selectDescendantRoute(TOS_MsgPtr msg, uint8_t id, uint8_t resend, uint8_t monitor);


  command result_t forwardFailed();


  /**
   * Given a TOS_MstPtr, initialize its routing fields to a known
   * state, specifying that the message is originating from this node.
   * This known state can then be used by selectRoute() to fill in
   * the necessary data.
   *
   * @param msg Message to select route for and fill in init data.
   *
   * @return Should always return SUCCESS.
   *
   */

  command result_t initializeFields(TOS_MsgPtr msg, uint8_t id);
  
  
  /**
   * Given a TinyOS message buffer, provide a pointer to the data
   * buffer within it that an application can use as well as its
   * length. Unlike the getBuffer of the Send interface, this can
   * be called freely and does not modify the buffer.
   *
   * @param msg The message to get the data region of.
   *
   * @param length Pointer to a field to store the length of the data region.
   *
   * @return A pointer to the data region.
   */
  
  command uint8_t* getBuffer(TOS_MsgPtr msg, uint16_t* len);
}
