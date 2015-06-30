// $Id: FieldApp.nc,v 1.3 2004/02/11 00:57:56 idgay Exp $

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
includes Field;
configuration FieldApp { 
  provides interface StdControl;
}
implementation 
{
  // We assume that TimerC and the communication channel are initialised
  // elsewhere
  components Field, TimerC, GENERICCOMMPROMISCUOUS as Comm, LedsC, Command, Ping, Attr,
    RandomLFSR, ServiceSchedulerC, QueuedSend, TupleRouterM;

  StdControl = Field.StdControl;
  StdControl = Ping.StdControl;

  Field.WakeupMsg -> Comm.ReceiveMsg[AM_WAKEUPMSG];
  Field.FieldMsg -> Comm.ReceiveMsg[AM_FIELDMSG];
  Field.FieldReplyMsg -> QueuedSend.SendMsg[AM_FIELDREPLYMSG];
  Field.SpyReplyMsg -> Comm.ReceiveMsg[AM_FIELDREPLYMSG];
  Field.CommandUse -> Command;
  Field.SleepTimer -> TimerC.Timer[unique("Timer")];
  Field.MsgTimer -> TimerC.Timer[unique("Timer")];
  Field.Leds -> LedsC;
  Field.Random -> RandomLFSR;
  Field.SchedulerClt -> ServiceSchedulerC;
  Field.ServiceScheduler -> ServiceSchedulerC;
  Field.WakeTinyDB -> TupleRouterM.ForceAwake;

  Ping.PingCmd -> Command.Cmd[unique("Command")];
  Ping.AttrUse -> Attr;
}

