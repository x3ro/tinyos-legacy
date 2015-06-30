/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
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
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     Mark Yarvis, York Liu
 *
 */

configuration Flood {
   provides {
      interface StdControl as Control;
      interface Send[uint8_t app];
      interface Receive[uint8_t app];
      interface Intercept[uint8_t app];
      interface SingleHopMsg;  // access to single hop packet decoding
      interface MultiHopMsg; // access to multihop packet decoding
      interface FloodMsg; // access to flood packet decoding
      interface SendMHopMsg[uint8_t app];
      
   }
   uses {
      event result_t radioIdle();
   }
}

implementation {
   components FloodM, 
       LedsC,
#if USE_SEND_QUEUE
              QueuingSingleHopManager as SingleHopManager;
#else
              SingleHopManager;
#endif

   FloodM.Control = Control;
   FloodM.Send = Send;
   FloodM.SendMHopMsg = SendMHopMsg;
   FloodM.Receive = Receive;
   FloodM.Intercept = Intercept;
   FloodM.FloodMsg = FloodMsg;
   FloodM.MultiHopMsg = MultiHopMsg;
   SingleHopManager.SingleHopMsg = SingleHopMsg;
   FloodM.radioIdle = radioIdle;

   FloodM.Leds->LedsC;

   FloodM.SingleHopControl -> SingleHopManager;
   FloodM.SingleHopSend -> SingleHopManager.SendMsg[AM_ID_FLOOD];
   FloodM.SingleHopReceive -> SingleHopManager.ReceiveMsg[AM_ID_FLOOD];
   FloodM.SingleHopPayload -> SingleHopManager;
   FloodM.singleHopRadioIdle <- SingleHopManager.radioIdle;
}
