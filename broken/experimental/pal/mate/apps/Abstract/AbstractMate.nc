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
includes Bombilla;
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

configuration AbstractMate {}
implementation
{
  components BombillaEngine as VM;
  components Main, TimerC, LedsC, GenericComm;
  components RandomLFSR;
  components BStacks, BBuffer, BContextSynch, BInstruction;
  components BQueue, BVirusTau as BVirus;
  components BLocksSafe as BLocks;

  components Photo, Temp;
  
  components OPhalt, OPputled, OPcopy, OPadd, OPland, OPlor, OPlnot;
  components OPand, OPor, OPnot, OPerr, OPcpull, OPcpush, OPdepth;
  components OPctrue, OPcfalse, OPinv, OPsense, OPid, OPrand, OPret;
  components OPcall2, OPbpush1;
  components OPpushc6, OPgetvar4, OPsetvar4;
  
  // The initializations
  Main.StdControl -> VM;
  VM.SubControlTimer -> TimerC;
  VM.SubControlNetwork -> GenericComm.Control;
  VM.SubControl -> BVirus;
  VM.SubControl -> Photo;
  VM.SubControl -> Temp;
  
  // Two main VM timers
  VM.ClockTimer -> TimerC.Timer[unique("Timer")];

  // VM communication
  VM.SendError -> GenericComm.SendMsg[AM_BOMBILLAERRORMSG];
  VM.ReceivePacket ->  GenericComm.ReceiveMsg[AM_BOMBILLAPACKETMSG];

  // Actuators
  VM.Leds -> LedsC;

  // Misc. functions
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
  VM.Locks -> BLocks.Locks;
  BLocks.BombillaError -> VM;

  // Queue ADT component
  VM.Queue -> BQueue.Queue;
  BQueue.BombillaError -> VM;

  // Synchronization component
  VM.Synch -> BContextSynch;
  VM.Analysis -> BContextSynch;
  BContextSynch.BombillaError -> VM;
  BContextSynch.Locks -> BLocks;
  BContextSynch.Queue -> BQueue;
  BContextSynch.Instruction -> BInstruction;
  
  // Viral propagation component
  VM.Virus -> BVirus;
  BVirus.SubControl -> GenericComm;
  BVirus.VersionTimer->TimerC.Timer[unique("Timer")];
  BVirus.VersionReceive->GenericComm.ReceiveMsg[AM_BOMBILLAVERSIONMSG];
  BVirus.VersionSend->GenericComm.SendMsg[AM_BOMBILLAVERSIONMSG];
  BVirus.CapsuleTimer->TimerC.Timer[unique("Timer")];
  BVirus.CapsuleReceive->GenericComm.ReceiveMsg[AM_BOMBILLACAPSULEMSG];
  BVirus.CapsuleSend->GenericComm.SendMsg[AM_BOMBILLACAPSULEMSG];
  BVirus.Random -> RandomLFSR;

  // Instructions

  VM.Bytecode[OPhalt] -> OPhalt;
  VM.Bytecode[OPputled] -> OPputled;
  VM.Bytecode[OPadd] -> OPadd;
  VM.Bytecode[OPcopy] -> OPcopy;
  VM.Bytecode[OPland] -> OPland;
  VM.Bytecode[OPlor] -> OPlor;
  VM.Bytecode[OPlnot] -> OPlnot;
  VM.Bytecode[OPnot] -> OPnot;
  VM.Bytecode[OPinv] -> OPinv;
  VM.Bytecode[OPcpull] -> OPcpull;
  VM.Bytecode[OPcpush] -> OPcpush;
  VM.Bytecode[OPerr] -> OPerr;
  VM.Bytecode[OPdepth] -> OPdepth;
  VM.Bytecode[OPid] -> OPid;
  VM.Bytecode[OPrand] -> OPrand;
  VM.Bytecode[OPret] -> OPret;
  VM.Bytecode[OPsense] -> OPsense;
  
  VM.Bytecode[OPcall0] -> OPcall2;
  VM.Bytecode[OPcall0+1] -> OPcall2;
  VM.Bytecode[OPcall0+2] -> OPcall2;
  VM.Bytecode[OPcall0+3] -> OPcall2;
  
  VM.Bytecode[OPbpush0] -> OPbpush1;
  VM.Bytecode[OPbpush0+1] -> OPbpush1;
  
  VM.Bytecode[OPgetvar] -> OPgetvar4;
  VM.Bytecode[OPgetvar+1] -> OPgetvar4;
  VM.Bytecode[OPgetvar+2] -> OPgetvar4;
  VM.Bytecode[OPgetvar+3] -> OPgetvar4;
  VM.Bytecode[OPgetvar+4] -> OPgetvar4;
  VM.Bytecode[OPgetvar+5] -> OPgetvar4;
  VM.Bytecode[OPgetvar+6] -> OPgetvar4;
  VM.Bytecode[OPgetvar+7] -> OPgetvar4;
  VM.Bytecode[OPgetvar+8] -> OPgetvar4;
  VM.Bytecode[OPgetvar+9] -> OPgetvar4;
  VM.Bytecode[OPgetvar+10] -> OPgetvar4;
  VM.Bytecode[OPgetvar+11] -> OPgetvar4;
  VM.Bytecode[OPgetvar+12] -> OPgetvar4;
  VM.Bytecode[OPgetvar+13] -> OPgetvar4;
  VM.Bytecode[OPgetvar+14] -> OPgetvar4;
  VM.Bytecode[OPgetvar+15] -> OPgetvar4;
  
  VM.Bytecode[OPsetvar] -> OPsetvar4;
  VM.Bytecode[OPsetvar+1] -> OPsetvar4;
  VM.Bytecode[OPsetvar+2] -> OPsetvar4;
  VM.Bytecode[OPsetvar+3] -> OPsetvar4;
  VM.Bytecode[OPsetvar+4] -> OPsetvar4;
  VM.Bytecode[OPsetvar+5] -> OPsetvar4;
  VM.Bytecode[OPsetvar+6] -> OPsetvar4;
  VM.Bytecode[OPsetvar+7] -> OPsetvar4;
  VM.Bytecode[OPsetvar+8] -> OPsetvar4;
  VM.Bytecode[OPsetvar+9] -> OPsetvar4;
  VM.Bytecode[OPsetvar+10] -> OPsetvar4;
  VM.Bytecode[OPsetvar+11] -> OPsetvar4;
  VM.Bytecode[OPsetvar+12] -> OPsetvar4;
  VM.Bytecode[OPsetvar+13] -> OPsetvar4;
  VM.Bytecode[OPsetvar+14] -> OPsetvar4;
  VM.Bytecode[OPsetvar+15] -> OPsetvar4;

  VM.Bytecode[OPpushc] -> OPpushc6;
  VM.Bytecode[OPpushc+1] -> OPpushc6;
  VM.Bytecode[OPpushc+2] -> OPpushc6;
  VM.Bytecode[OPpushc+3] -> OPpushc6;
  VM.Bytecode[OPpushc+4] -> OPpushc6;
  VM.Bytecode[OPpushc+5] -> OPpushc6;
  VM.Bytecode[OPpushc+6] -> OPpushc6;
  VM.Bytecode[OPpushc+7] -> OPpushc6;
  VM.Bytecode[OPpushc+8] -> OPpushc6;
  VM.Bytecode[OPpushc+9] -> OPpushc6;
  VM.Bytecode[OPpushc+10] -> OPpushc6;
  VM.Bytecode[OPpushc+11] -> OPpushc6;
  VM.Bytecode[OPpushc+12] -> OPpushc6;
  VM.Bytecode[OPpushc+13] -> OPpushc6;
  VM.Bytecode[OPpushc+14] -> OPpushc6;
  VM.Bytecode[OPpushc+15] -> OPpushc6;
  VM.Bytecode[OPpushc+16] -> OPpushc6;
  VM.Bytecode[OPpushc+17] -> OPpushc6;
  VM.Bytecode[OPpushc+18] -> OPpushc6;
  VM.Bytecode[OPpushc+19] -> OPpushc6;
  VM.Bytecode[OPpushc+20] -> OPpushc6;
  VM.Bytecode[OPpushc+21] -> OPpushc6;
  VM.Bytecode[OPpushc+22] -> OPpushc6;
  VM.Bytecode[OPpushc+23] -> OPpushc6;
  VM.Bytecode[OPpushc+24] -> OPpushc6;
  VM.Bytecode[OPpushc+25] -> OPpushc6;
  VM.Bytecode[OPpushc+26] -> OPpushc6;
  VM.Bytecode[OPpushc+27] -> OPpushc6;
  VM.Bytecode[OPpushc+28] -> OPpushc6;
  VM.Bytecode[OPpushc+29] -> OPpushc6;
  VM.Bytecode[OPpushc+30] -> OPpushc6;
  VM.Bytecode[OPpushc+31] -> OPpushc6;

  OPhalt.Synch -> BContextSynch;
  
  OPputled.Leds -> LedsC;
  OPputled.BombillaStacks -> BStacks;
  OPputled.BombillaTypes -> BStacks;

  OPland.Types -> BStacks;
  OPland.Stacks -> BStacks;
  
  OPpushc6.BombillaStacks -> BStacks;

  OPgetvar4.Types -> BStacks;
  OPgetvar4.Stacks -> BStacks;
  OPgetvar4.Locks -> BLocks;
  OPgetvar4.Error -> VM;

  OPsetvar4.Types -> BStacks;
  OPsetvar4.Stacks -> BStacks;
  OPsetvar4.Locks -> BLocks;
  OPsetvar4.Error -> VM;

  OPcall2.Stacks -> BStacks;

  OPbpush1.Stacks -> BStacks;
  
  OPadd.Stacks -> BStacks;
  OPadd.Error -> VM;
  OPadd.Buffer -> BBuffer;

  OPcopy.Stacks -> BStacks;

  OPsense.Stacks -> BStacks;
  OPsense.Queue -> BQueue;
  OPsense.Error -> VM;
  OPsense.Types -> BStacks;
  OPsense.Synch -> BContextSynch;
  OPsense.Sensors[BOMB_DATA_PHOTO] -> Photo;
  OPsense.Sensors[BOMB_DATA_TEMP] -> Temp;


  OPret.Stacks -> BStacks;

  OPrand.Random -> RandomLFSR;
  OPrand.Stacks -> BStacks;

  OPid.Stacks -> BStacks;

  OPdepth.Stacks -> BStacks;

  OPerr.Error -> VM;

  OPcpush.Stacks -> BStacks;

  OPcpull.Stacks -> BStacks;
  OPcpull.Types -> BStacks;

  OPinv.Stacks -> BStacks;
  OPinv.Types -> BStacks;

  OPnot.Stacks -> BStacks;
  OPnot.Types -> BStacks;

  OPlnot.Stacks -> BStacks;
  OPlnot.Types -> BStacks;

  OPlor.Stacks -> BStacks;
  OPlor.Types -> BStacks;

  OPand.Stacks -> BStacks;
  OPand.Types -> BStacks;

  OPor.Stacks -> BStacks;
  OPor.Types -> BStacks;

  OPnot.Stacks -> BStacks;
  OPnot.Types -> BStacks;
}
