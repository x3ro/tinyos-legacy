/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: MsgBuffersC.nc,v 1.5 2003/07/10 22:04:30 cssharp Exp $

configuration MsgBuffersC
{
  provides interface MsgBuffers;
}
implementation
{
  components MsgBuffersM
           , DiagMsgC
	   , TimerC
	   , TimedLedsC
	   , SystemGenericCommC as Comm
	   ;

  MsgBuffers = MsgBuffersM;

  MsgBuffersM.DiagMsg -> DiagMsgC;
  MsgBuffersM.Timer -> TimerC.Timer[unique("Timer")];
  MsgBuffersM.TimedLeds -> TimedLedsC;
  MsgBuffersM.ReceiveMsg -> Comm.ReceiveMsg[11];
}

