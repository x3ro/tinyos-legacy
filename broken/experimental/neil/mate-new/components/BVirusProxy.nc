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

includes Bombilla;
includes BombillaMsgs;

configuration BVirusProxy {
  provides interface BombillaVirus;
}

implementation {
  components BVirusTauPatched as Virus; // if Virus component changes,
                                        // just alter this line
  
  components GenericComm, TimerC, RandomLFSR, Main;
  
  BombillaVirus = Virus;

  Main.StdControl -> Virus;
  Virus.SubControl -> GenericComm;
  Virus.VersionTimer->TimerC.Timer[unique("Timer")];
  Virus.VersionReceive->GenericComm.ReceiveMsg[AM_BOMBILLAVERSIONMSG];
  Virus.VersionSend->GenericComm.SendMsg[AM_BOMBILLAVERSIONMSG];
  Virus.CapsuleTimer->TimerC.Timer[unique("Timer")];
  Virus.CapsuleReceive->GenericComm.ReceiveMsg[AM_BOMBILLACAPSULEMSG];
  Virus.CapsuleSend->GenericComm.SendMsg[AM_BOMBILLACAPSULEMSG];
  Virus.Random -> RandomLFSR;
  
}
  
