/*									tab:4
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

/* Authors:             Joe Polastre
 * 
 * $Id: GDI2SoftBase.nc,v 1.2 2003/10/07 21:45:32 idgay Exp $
 */

/**
 * Platforms:
 * <p>
 * Mica2DOT platform
 *
 **/

includes GDI2SoftMsg;

configuration GDI2SoftBase {
}
implementation {
  components Main, GDI2SoftBaseM, VirtualComm as Comm, LedsC, TimerC, \
             CC1000RadioIntM, CC1000ControlM, \
             MHSender, ParentSelection, Bcast, BcastM;

  Main.StdControl -> TimerC;
  Main.StdControl -> Bcast;
  Main.StdControl -> Comm;
  Main.StdControl -> MHSender;
  Main.StdControl -> GDI2SoftBaseM;

  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_WS_REV2_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_B_REV2_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_CALIB_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_ACK_REV2_MSG];

  GDI2SoftBaseM.ReceiveNetwork -> Bcast.Receive[AM_GDI2SOFT_NETWORK_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_NETWORK_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_NETWORK_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_RATE_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_RATE_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_RESET_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_RESET_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_QUERY_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_QUERY_MSG];

  GDI2SoftBaseM.SetListeningMode -> CC1000RadioIntM.SetListeningMode;
  GDI2SoftBaseM.GetListeningMode -> CC1000RadioIntM.GetListeningMode;
  GDI2SoftBaseM.SetTransmitMode -> CC1000RadioIntM.SetTransmitMode;
  GDI2SoftBaseM.GetTransmitMode -> CC1000RadioIntM.GetTransmitMode;

  GDI2SoftBaseM.setRouteUpdateInterval -> ParentSelection.setRouteUpdateInterval;

  GDI2SoftBaseM.ForwardDone <- BcastM.ForwardDone;

  GDI2SoftBaseM.CC1000Control -> CC1000ControlM;

  GDI2SoftBaseM.Leds -> LedsC;

  GDI2SoftBaseM.NetworkTimer -> TimerC.Timer[unique("Timer")];


}
