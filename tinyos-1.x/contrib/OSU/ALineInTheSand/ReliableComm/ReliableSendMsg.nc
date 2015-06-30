/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */



/* 
 * Authors: Hongwei Zhang, Anish Arora
 */


// the full send interface
includes AM;
interface ReliableSendMsg
{ 
  command result_t send(uint16_t address, uint8_t length, TOS_MsgPtr msg, uint16_t fromAddr, uint8_t   fromQueuePos); 
  /* "fromAddr" denotes the ID of the node that has sent the message m, and "fromQueuePos" denotes the local sequence number of the sender of msg */

  event result_t sendDone(TOS_MsgPtr msg, result_t success);

  //command result_t baseAck(TOS_MsgPtr msg, uint16_t fromAddr, uint8_t   fromQueuePos);

  //command result_t sendFlush(uint8_t len);     //empty send buffer  
}
