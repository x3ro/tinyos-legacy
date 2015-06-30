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

includes Spantree;

/**
 * Spanning tree construction. See SpantreeM.nc for details.
 */
configuration SpantreeC
{
  provides interface Spantree;
}
implementation
{
  components Main, SpantreeM, GenericComm as Comm, QueuedSend, TimerC, NoLeds;

  Spantree = SpantreeM;

  Main.StdControl -> SpantreeM;
  Main.StdControl -> Comm;

  SpantreeM.SendMsg -> QueuedSend.SendMsg[AM_SPANTREEMSG];
  //QueuedSend.RealSendMsg[AM_SPANTREEMSG] -> Comm.SendMsg[AM_SPANTREEMSG];
  SpantreeM.ReceiveMsg -> Comm.ReceiveMsg[AM_SPANTREEMSG];
  SpantreeM.Timer -> TimerC.Timer[unique("Timer")];

}
