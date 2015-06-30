
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

/*
 *  * Author: Phil Buonadonna
 *   * $Revision: 1.1 $
 *    */

/**
 *  * @author Phil Buonadonna
 *   */


/*
 * "Copyright (c) 2000-2005 The Regents of the University of Southern California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Authors: Sumit Rangwala
 * Embedded Networks Laboratory, University of Southern California
 */


includes AM;

configuration QueuedSend {
  provides {
    interface StdControl;
    interface SendMsg[uint8_t id];
    interface QueueControl;
    interface UpdateHdr;
  }
  uses {
      interface SendMsg as SerialSendMsg[uint8_t id];
  }
  
}

implementation {
  components QueuedSendM, GenericCommPromiscuous as Comm, RandomLFSR as Random, 
#if defined(LOG_QUEUE) || defined(LOG_SDLOSS)
  SerialQueuedSend,
#endif 
  TimerC,
  LedsC; 
  
  
  StdControl = QueuedSendM;
  QueueControl = QueuedSendM;
  UpdateHdr = QueuedSendM;
  SendMsg = QueuedSendM.QueueSendMsg;
  SerialSendMsg = QueuedSendM.SerialSendMsg;

  /* I think this was a part of standard QueuedSend but now it is
   * exported as an external interface and the wiring is done in the RateControl
   * Module 
   */
  //QueuedSendM.SerialSendMsg -> Comm.SendMsg;
  //SerialSendMsg = QueuedSendM.SerialSendMsg;
  
  QueuedSendM.MsgControl -> Comm;
  QueuedSendM.MacBackoff  -> Comm;
  QueuedSendM.MacControl  -> Comm;

  QueuedSendM.Random -> Random;
#if defined(LOG_QUEUE) || defined(LOG_SDLOSS)
  QueuedSendM.LogMsg       -> SerialQueuedSend.SendMsg[AM_LOG];
  QueuedSendM.LogControl    -> SerialQueuedSend;
#endif 
  
  QueuedSendM.SendTimeoutTimer -> TimerC.Timer[unique("Timer")]; 
  QueuedSendM.Leds -> LedsC;
}
