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

includes Collective;

configuration Collective 
{
  provides interface Reduce;
  provides interface Barrier;
  provides interface Command;
}
implementation
{
  components Main, ReduceM, BarrierM, CommandM, QueuedSend,
    GenericComm as Comm, SpantreeC, TimerC;

  Reduce = ReduceM;
  Barrier = BarrierM;
  Command = CommandM;

  Main.StdControl -> Comm;
  Main.StdControl -> CommandM;

  ReduceM.Spantree -> SpantreeC;
  ReduceM.SendMsg -> Comm.SendMsg[AM_REDUCEMSG];
  ReduceM.ReceiveMsg -> Comm.ReceiveMsg[AM_REDUCEMSG];
  ReduceM.Timer -> TimerC.Timer[unique("Timer")];
  ReduceM.Command -> CommandM;

  CommandM.SendMsg -> QueuedSend.SendMsg[AM_COMMANDMSG];
  //QueuedSend.RealSendMsg[AM_COMMANDMSG] -> Comm.SendMsg[AM_COMMANDMSG];
  CommandM.ReceiveMsg -> Comm.ReceiveMsg[AM_COMMANDMSG];

}
