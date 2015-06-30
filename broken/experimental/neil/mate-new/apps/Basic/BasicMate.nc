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
 * Date last modified:  9/10/02
 *
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

configuration BasicMate {}
implementation
{
  components BombillaCore as VM;
  components Main, TimerC, LedsC, Photo, Temp, GenericComm;
  components PotC, RandomLFSR, Bap, AMStandard;
  components BStacks, BBuffer, BLocksSafe, BSynch, BInstruction, BQueue;
  components BVirus;

  // The initializations
  Main.StdControl -> VM;
  VM.StdControlPhoto -> Photo.StdControl;
  VM.StdControlTemp  -> Temp.StdControl;
  VM.StdControlTimer -> TimerC;
  VM.StdControlNetwork -> GenericComm.Control;
  VM.StdControlNetwork -> Bap;

  // Two main VM timers
  VM.ClockTimer -> TimerC.Timer[unique("Timer")];
  VM.TimeoutTimer -> TimerC.Timer[unique("Timer")];

  // VM communication
  VM.SendPacket -> GenericComm.SendMsg[AM_BOMBILLAPACKETMSG];
  VM.SendError -> GenericComm.SendMsg[AM_BOMBILLAERRORMSG];
  VM.ReceivePacket ->  GenericComm.ReceiveMsg[AM_BOMBILLAPACKETMSG];
  VM.SendAdHoc -> Bap.SendData;
  VM.isAdHocActive -> Bap.active;
  VM.sendDone <- GenericComm.sendDone;

  // Sensors
  VM.PhotoADC -> Photo;
  VM.TempADC -> Temp;

  // Actuators
  VM.Leds -> LedsC;
  VM.Pot -> PotC;

  // Misc. functions
  VM.networkActivity -> AMStandard.activity;
  VM.Random -> RandomLFSR;
  
  /****** SUBSYSTEMS ********/
  // Instruction class ADT component
  VM.Instruction -> BInstruction.Instruction;
  
  // Operand/return stack ADT component
  VM.Stacks -> BStacks.Stacks;
  BStacks.BombillaError -> VM;

  // Data buffer ADT component
  VM.Buffer -> BBuffer.Buffer;
  BBuffer.BombillaError -> VM;

  // Lock ADT component
  VM.Locks -> BLocksSafe.Locks;
  BLocksSafe.BombillaError -> VM;

  // Queue ADT component
  VM.Queue -> BQueue.Queue;
  BQueue.BombillaError -> VM;

  // Synchronization component
  VM.Synch -> BSynch.Synch;
  BSynch.BombillaError -> VM;
  BSynch.Locks -> BLocksSafe.Locks;

  // Viral propagation component
  VM.Virus -> BVirus;
  BVirus.VersionTimer->TimerC.Timer[unique("Timer")];
  BVirus.VersionReceive->GenericComm.ReceiveMsg[AM_BOMBILLAVERSIONMSG];
  BVirus.VersionSend->GenericComm.SendMsg[AM_BOMBILLAVERSIONMSG];
  BVirus.CapsuleTimer->TimerC.Timer[unique("Timer")];
  BVirus.CapsuleReceive->GenericComm.ReceiveMsg[AM_BOMBILLACAPSULEMSG];
  BVirus.CapsuleSend->GenericComm.SendMsg[AM_BOMBILLACAPSULEMSG];
  BVirus.Random -> RandomLFSR;
}
