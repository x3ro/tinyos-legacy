/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

/** 
 * Queued sends. See QueuedSendM.nc for details.
 */
configuration QueuedSend 
{
  provides interface SendMsg[uint8_t id];
}
implementation
{
  components Main, TuningC, QueuedSendM, GenericComm as Comm, 
    TimerC as Timer, NoLeds;

  SendMsg = QueuedSendM;

  Main.StdControl -> QueuedSendM;
  QueuedSendM.Tuning -> TuningC;
  QueuedSendM.Timer -> Timer.Timer[unique("Timer")];
  QueuedSendM.RealSendMsg -> Comm.SendMsg;
  QueuedSendM.Leds -> NoLeds;

}
