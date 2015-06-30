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
 * Authors:	Gilman Tolle
 *
 */

includes SNMS;
includes Drip;

configuration DripC {
  provides {
    interface StdControl;
    interface Receive[uint8_t id];
    interface Drip[uint8_t id];
  }
}

implementation {
  components 
  DripM, 
    SharedMsgBufM,
    GenericComm as Comm, 
    TimerC, 
    RandomLFSR, 
    NoLeds as Leds;

#ifdef DBG_DRIP
  components EventLoggerC;
#endif

  StdControl = DripM;
  Receive = DripM.Receive;
  Drip = DripM;
  
  DripM.SubControl -> SharedMsgBufM;
  DripM.SubControl -> Comm;
  DripM.SubControl -> TimerC;

  DripM.ReceiveMsg -> Comm.ReceiveMsg[AM_DRIPMSG];
  DripM.SendMsg -> Comm.SendMsg[AM_DRIPMSG];

  DripM.SendTimer -> TimerC.Timer[unique("Timer")];

  DripM.Leds -> Leds;

  DripM.Random -> RandomLFSR;

  DripM.SharedMsgBuf -> SharedMsgBufM.SharedMsgBuf[BUF_SNMS];

#ifdef DBG_DRIP
  DripM.EventLogger -> EventLoggerC;
#endif
}

