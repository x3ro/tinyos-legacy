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

/**
   TestBombilla is a test application for Bombilla, the TinyOS
   communication-centric bytecode interpreter. It includes the VM and
   all of its subcomponents. Installing this application on a mote
   will install Bombilla, which by default has a program similar to
   CntToLedsAndRFM. new programs can be installed on motes over the
   network. A Bombilla tutorial and reference are provided in the
   TinyOS release, outlining its capabilities and uses.
*/

configuration AbstractMateSender {}
implementation
{
  components BombillaEngine as VM;
  components Main; 
    
  components OPhalt, OPputled, OPcopy, OPadd, OPland, OPlnot; 
  components OPbpush1;
  components OPpushc6, OPgetvar4, OPsetvar4;
  components OPsendr, OPsend, OPuart;
  components OPbclear, OPbhead;
  components OPcall2, OPret;

  components ClockContext;
  
  Main.StdControl -> VM;

  VM.Bytecode[OPret] -> OPret;

  VM.Bytecode[OPcall0] -> OPcall2;
  VM.Bytecode[OPcall0+1] -> OPcall2;
  VM.Bytecode[OPcall0+2] -> OPcall2;
  VM.Bytecode[OPcall0+3] -> OPcall2;

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

  VM.Bytecode[OPhalt] -> OPhalt;
  /*
  VM.Bytecode[OPputled] -> OPputled;
  VM.Bytecode[OPadd] -> OPadd;
  VM.Bytecode[OPcopy] -> OPcopy;
  VM.Bytecode[OPland] -> OPland;
  VM.Bytecode[OPlnot] -> OPlnot;
  VM.Bytecode[OPsendr] -> OPsendr;
  VM.Bytecode[OPuart] -> OPuart;
  VM.Bytecode[OPbpush0] -> OPbpush1;
  VM.Bytecode[OPbclear] -> OPbclear;
  VM.Bytecode[OPbhead] -> OPbhead;
  VM.Bytecode[OPgetvar] -> OPgetvar4;
  VM.Bytecode[OPsetvar] -> OPsetvar4;
  VM.Bytecode[OPpushc] -> OPpushc6;
  VM.Bytecode[OPpushc+1] -> OPpushc6;
  VM.Bytecode[OPpushc+7] -> OPpushc6;
  */
}
