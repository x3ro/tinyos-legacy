// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVRCommStack.nc,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $

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


/* This configuration provides the networking stack for the different software
 * components in BVR. It wires the queuing component, a UART diverter for 
 * the PC implementation, as well as the link estimator. The Link Estimator
 * is broken into two parts. The first is LinkEstimatorTaggerComm, which
 * marks every outgoing radio packet with a source and an increasing 16-bit sequence
 * number. This components is put after the queueing components, for it marks
 * even the retransmissions with a different sequence number. The other part is
 * the LinkEstimatorComm, which actually wires to the LinkEstimator component and
 * is involved in the quality estimation.
 */

configuration BVRCommStack {
  provides {
    interface StdControl;
    interface SendMsg[ uint8_t am];
    interface ReceiveMsg[ uint8_t am];
  }
}

implementation {
  components
             FilterLocalCommM
           , LinkEstimatorComm
           , BVRQueuedSendComm
           , LinkEstimatorTaggerCommM
#if defined(PLATFORM_PC)
           , UARTInterceptComm
#endif
           , GenericCommReallyPromiscuous
           ;

/*********** ************/

  StdControl = FilterLocalCommM;
  SendMsg    = FilterLocalCommM;
  ReceiveMsg = FilterLocalCommM;

  FilterLocalCommM.BottomStdControl -> LinkEstimatorComm.StdControl;
  FilterLocalCommM.BottomSendMsg    -> LinkEstimatorComm.SendMsg;
  FilterLocalCommM.BottomReceiveMsg -> LinkEstimatorComm.ReceiveMsg;

  LinkEstimatorComm.BottomStdControl -> BVRQueuedSendComm.StdControl;
  LinkEstimatorComm.BottomSendMsg    -> BVRQueuedSendComm.SendMsg;
  LinkEstimatorComm.BottomReceiveMsg -> BVRQueuedSendComm.ReceiveMsg;

  BVRQueuedSendComm.BottomStdControl -> LinkEstimatorTaggerCommM.StdControl;
  BVRQueuedSendComm.BottomSendMsg    -> LinkEstimatorTaggerCommM.SendMsg;
  BVRQueuedSendComm.BottomReceiveMsg -> LinkEstimatorTaggerCommM.ReceiveMsg;
#if defined(PLATFORM_PC)
  // Divert UART traffic to debugging
  LinkEstimatorTaggerCommM.BottomStdControl -> UARTInterceptComm;
  LinkEstimatorTaggerCommM.BottomSendMsg    -> UARTInterceptComm;
  LinkEstimatorTaggerCommM.BottomReceiveMsg -> UARTInterceptComm;

  UARTInterceptComm.BottomStdControl -> GenericCommReallyPromiscuous;
  UARTInterceptComm.BottomSendMsg    -> GenericCommReallyPromiscuous;
  UARTInterceptComm.BottomReceiveMsg -> GenericCommReallyPromiscuous;
#else
  LinkEstimatorTaggerCommM.BottomStdControl -> GenericCommReallyPromiscuous;
  LinkEstimatorTaggerCommM.BottomSendMsg    -> GenericCommReallyPromiscuous;
  LinkEstimatorTaggerCommM.BottomReceiveMsg -> GenericCommReallyPromiscuous;
#endif

}
