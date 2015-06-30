/*
 * Copyright (C) 2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye
 *
 * This interface is for message transmission and reception at the MAC layer
 */

interface MacMsg
{
  /**
   * send a message
   * @param msg Pointer to the message buffer to be sent
   * @param length The length of entire message including all headers
   * @param toAddr The receivers address. If it is TOS_BCAST_ADDR, will
   *    broadcast, otherwise will unicast.
   * @return Returns SUCCESS if accepted by MAC.
   *    Returns FAIL if not accepted.
   */
  command result_t send(void* msg, uint8_t length, uint16_t toAddr);

  /**
   * cancel a message to be sent (after calling MacMsg.send)
   * note MAC only buffers one message
   * @param msg Pointer to the message buffer to be cancelled
   * @return Returns SUCCESS if MAC successfully cancels the sending.
   *    Returns FAIL if MAC already started sending the msg.
   */
  command result_t sendCancel(void* msg);

  /**
   * signal transmission of a message is done
   * @param msg Pointer to the message buffer being sent
   * @param result SUCCESS if sending is successful; 
   *    FAIL if failed to send out
   */
  event void sendDone(void* msg, result_t result);
  
  /**
   * signal reception of a message is done
   * @param msg Pointer to the message buffer being received
   */
  event void* receiveDone(void* msg);
}
