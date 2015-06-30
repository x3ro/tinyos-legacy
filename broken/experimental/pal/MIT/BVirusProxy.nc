/*
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Philip Levis
 *              Neil Patel
 * Date last modified:  9/10/02
 *
 */

/**
 * @author Philip Levis
 * @author Neil Patel
 */


includes Bombilla;
includes MultiHop;

configuration BVirusProxy {
  provides interface BombillaVirus;
}

implementation {
  components BVirusExtended as Virus; // if Virus component changes,
                                        // just alter this line
  
  components GenericComm, QueuedSend, TimerC, RandomLFSR, Main, GridRouter;
  components MultiHopEngineGridM, GenericCommPromiscuous;
  
  BombillaVirus = Virus;

  Main.StdControl -> Virus;
  Virus.SubControl -> GenericComm;
  Virus.SubControl -> QueuedSend;
  Virus.VersionTimer->TimerC.Timer[unique("Timer")];
  Virus.VersionReceive->GenericComm.ReceiveMsg[AM_BOMBILLAVERSIONMSG];
  Virus.VersionSend->QueuedSend.SendMsg[AM_BOMBILLAVERSIONMSG];
  Virus.CapsuleTimer->TimerC.Timer[unique("Timer")];
  Virus.CapsuleReceive->GenericComm.ReceiveMsg[AM_BOMBILLACAPSULEMSG];
  Virus.CapsuleSend->QueuedSend.SendMsg[AM_BOMBILLACAPSULEMSG];
  Virus.BCastTimer->TimerC.Timer[unique("Timer")];
  Virus.BCastReceive->GenericComm.ReceiveMsg[67];
  Virus.BCastSend->QueuedSend.SendMsg[67];

  
  Virus.Random -> RandomLFSR;
  Virus -> GridRouter.Receive[66];
  Virus -> GridRouter.Intercept[66];
  Virus -> GridRouter.Snoop[66];
  MultiHopEngineGridM.ReceiveMsg[66] -> GenericCommPromiscuous.ReceiveMsg[66];
}
  
