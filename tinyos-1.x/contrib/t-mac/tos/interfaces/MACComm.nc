// $Id: MACComm.nc,v 1.2 2005/09/23 12:59:39 palfrey Exp $

/*									tab:4
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye
 * Date created: 1/21/2003
 *
 * This interface is for message transmission and reception at the MAC layer
 *
 */

/**
 * @author Wei Ye
 */


interface MACComm
{
   // Broadcast a message
   
   command result_t broadcastMsg(void* msg, uint8_t length);
   event result_t  broadcastDone(void* msg);
   
   // Unicast a message. Will receives two signals:
   //   1) txFragDone after each fragment except the last one. 
   //   2) unicastDone after entire msg (last fragment).
   // If msg only has one fragment, will only receive the second signal.

   command result_t unicastMsg(void* msg, uint8_t length, uint16_t toAddr); //, uint8_t numFrags);
   /*command result_t txNextFrag(void* frag);
   event result_t txFragDone(void* frag);*/
   event result_t unicastDone(void* msg, result_t success); //, uint8_t txFragCount);
   
   // txReset forces MAC drop current buffered msg, and accept a new one
   
   command result_t txReset();

   /* send a raw msg  (i.e. feed straight through to PhyComm) */
   command result_t txRaw(uint8_t *msg, uint8_t length);
   /* recv a raw msg (one that we don't know what to with) */
   event result_t txRawDone(uint8_t *msg);
   
   // signal received message
   
   event void* rxMsgDone(void* msg, uint16_t rssi);
   event void* rxWeirdDone(void* msg, uint16_t rssi); // emitted when we see a packet that we don't know the type for
}
