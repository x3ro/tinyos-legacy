//$Id: DripSendC.nc,v 1.1 2005/10/27 21:29:43 gtolle Exp $

/*								       
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

includes DripSend;

generic configuration DripSendC(uint8_t channel) {
  provides interface StdControl;
  provides interface Send;
  provides interface SendMsg;
  provides interface Receive;
}
implementation {

  components new DripSendM();

  components DripC;
  components DripStateC;
  components GroupManagerC;
  components LedsC;

  StdControl = DripSendM;
  StdControl = DripC;

  Send = DripSendM;
  SendMsg = DripSendM;
  Receive = DripSendM;
  
  DripSendM.DripReceive -> DripC.Receive[channel];
  DripSendM.Drip -> DripC.Drip[channel];
  DripC.DripState[channel] -> DripStateC.DripState[unique("DripState")];

  DripSendM.GroupManager -> GroupManagerC;
  DripSendM.Leds -> LedsC;
}
