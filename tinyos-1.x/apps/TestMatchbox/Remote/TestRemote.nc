// $Id: TestRemote.nc,v 1.3 2003/10/07 21:45:19 idgay Exp $

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
includes Matchbox;
includes AM;
includes Remote;
configuration TestRemote { }
implementation {
  components Main, Remote, Matchbox, UARTComm as Comm, LedsC;
#ifdef DEBUG
  components DebugC, TimerC;
#else
  components NoDebug;
#endif

  Main.StdControl -> Remote;
  Main.StdControl -> Matchbox;
  Main.StdControl -> Comm;

  Remote.FileDelete -> Matchbox;
  Remote.FileDir -> Matchbox;
  Remote.FileRead -> Matchbox.FileRead[unique("FileRead")];
  Remote.FileRename -> Matchbox;
  Remote.FileWrite -> Matchbox.FileWrite[unique("FileWrite")];

  Remote.ReceiveCommandMsg -> Comm.ReceiveMsg[AM_FSOPMSG];
  Remote.SendReplyMsg -> Comm.SendMsg[AM_FSREPLYMSG];
  Remote.sendDone <- Comm;

  Remote.Leds -> LedsC;

#ifdef DEBUG
  Main.StdControl -> TimerC;
  Matchbox.Debug -> DebugC;
  DebugC.SendMsg -> Comm.SendMsg[100];
  DebugC.Timer -> TimerC.Timer[unique("Timer")];
#else
  Matchbox.Debug -> NoDebug;
#endif
}
