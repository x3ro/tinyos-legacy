// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVRRouterPC.nc,v 1.1 2005/11/19 03:06:12 rfonseca76 Exp $

/*                                                                      
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * Authors:  Rodrigo Fonseca
 * Date Last Modified: 2005/05/26
 */

configuration BVRRouterPC {
  provides {
    interface StdControl;
    interface BVRSend[uint8_t slot];
    interface BVRReceive[uint8_t slot];
  }
  uses {
    command result_t routeTo(Coordinates *coords, uint16_t addr, uint8_t mode);
  }
}
implementation {
  components  BVRRouterPM as BVRRouterM   //StdControl provided
            , BVRStateC    //StdControl here
            , BVRCommStack //StdControl here 
            , BVRCommandC  //StdControl here
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
            , CC1000RadioC
#endif
            , UARTLogger as Logger //StdControl here
            , RandomLFSR as Random
            , TimerC as Timer
            ;

  //external
  BVRSend = BVRRouterM;
  BVRReceive = BVRRouterM;

  routeTo = BVRCommandC;

  //internal
  StdControl = Timer;
  StdControl = BVRCommStack;
  StdControl = BVRStateC;
  StdControl = BVRCommandC;
  StdControl = Logger;
  StdControl = BVRRouterM;

  BVRRouterM.Neighborhood -> BVRStateC.BVRNeighborhood;
  BVRRouterM.Locator -> BVRStateC.BVRLocator;
  BVRRouterM.SendMsg -> BVRCommStack.SendMsg[AM_BVR_APP_P_MSG];
  BVRRouterM.ReceiveMsg -> BVRCommStack.ReceiveMsg[AM_BVR_APP_P_MSG];

  BVRRouterM.ForwardDelayTimer -> Timer.Timer[unique("Timer")];
  BVRRouterM.Random -> Random;

  BVRRouterM.Logger -> Logger;
}
