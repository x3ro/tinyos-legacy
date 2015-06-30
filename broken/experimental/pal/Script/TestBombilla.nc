// $Id: TestBombilla.nc,v 1.1 2003/10/03 00:05:01 scipio Exp $

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

/* Authors:		Philip Levis
 * Date last modified:  9/10/02
 *
 */

/**
 * @author Philip Levis
 */


includes BombillaMsgs;

/**
   TestBombilla is a test application for Bombilla, the TinyOS
   communication-centric bytecode interpreter. It includes the VM and
   all of its subcomponents. Installing this application on a mote
   will install Bombilla, which by default has a program similar to
   CntToLedsAndRFM. new programs can be installed on motes over the
   network. A Bombilla tutorial and reference are provided in the
   TinyOS release, outlining its capabilities and uses.
*/

configuration TestBombilla { }
implementation
{
  components Main, Bombilla, TimerC, LedsC, Photo, Temp, GenericComm;
  components PotC, RandomLFSR, Bap, AMStandard;
  components BStacks, BBuffer, BLocksSafe, BSynch, BInstruction, BQueue;

  Main.StdControl -> Bombilla;
  Main.StdControl -> Bap;

  Bombilla.StdControlPhoto -> Photo.StdControl;
  Bombilla.StdControlTemp  -> Temp.StdControl;
//  Bombilla.StdControlAccel -> Accel.StdControl;
//  Bombilla.StdControlEEPROM -> EEPROM.StdControl;
  Bombilla.StdControlNetwork -> GenericComm.Control;

  Bombilla.Stacks -> BStacks.Stacks;
  BStacks.BombillaError -> Bombilla;

  Bombilla.Buffer -> BBuffer.Buffer;
  BBuffer.BombillaError -> Bombilla;

  Bombilla.Locks -> BLocksSafe.Locks;
  BLocksSafe.BombillaError -> Bombilla;

  Bombilla.Queue -> BQueue.Queue;
  BQueue.BombillaError -> Bombilla;

  Bombilla.Synch -> BSynch.Synch;
  BSynch.BombillaError -> Bombilla;
  BSynch.Locks -> BLocksSafe.Locks;

  Bombilla.networkActivity -> AMStandard.activity;
  
  Bombilla.Instruction -> BInstruction.Instruction;

  Bombilla.ClockTimer -> TimerC.Timer[unique("Timer")];
  Bombilla.PropagateTimer -> TimerC.Timer[unique("Timer")];
  Bombilla.TimeoutTimer -> TimerC.Timer[unique("Timer")];

  Bombilla.Leds -> LedsC;
  Bombilla.Random -> RandomLFSR;
  Bombilla.Pot -> PotC;

  Bombilla.PhotoADC -> Photo;
  Bombilla.TempADC -> Temp;
//  Bombilla.AccelXADC -> Accel.AccelX;
//  Bombilla.AccelYADC -> Accel.AccelY;
   
  Bombilla.SendCapsule -> GenericComm.SendMsg[AM_BOMBILLACAPSULEMSG];
  Bombilla.SendPacket -> GenericComm.SendMsg[AM_BOMBILLAPACKETMSG];
  Bombilla.SendError -> GenericComm.SendMsg[AM_BOMBILLAERRORMSG];

  Bombilla.ReceiveCapsule -> GenericComm.ReceiveMsg[AM_BOMBILLACAPSULEMSG];
  Bombilla.ReceivePacket ->  GenericComm.ReceiveMsg[AM_BOMBILLAPACKETMSG];
  
  Bombilla.sendDone <- GenericComm.sendDone;

  Bombilla.SendAdHoc -> Bap.SendData;
  Bombilla.isAdHocActive -> Bap.active;

}
