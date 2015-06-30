/*
 * "Copyright (c) 2004 and The Regents of the University 
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

includes Mate;

configuration MContextSynchProxy {
  provides {
    interface MateContextSynch;
    interface MateAnalysis;
    interface StdControl;
    interface MateContextStatus as ContextStatus[uint8_t contextID];
  }

  uses {
    interface MateBytecodeLock as CodeLocks[uint8_t param];
    interface MateBytecode as Bytecodes[uint8_t bytecode];
  }
  
}
implementation {
  components MContextSynch as Synch; // if the synch component changes, 
                                     // just alter here
  
  components MErrorProxy as Error;
  components MLocksProxy as Locks; 
  components MQueueProxy as Queue;
  components MStacksProxy as Stacks;
  components MHandlerStoreProxy as Store;
  components MateEngine as VM;
  
  components LedsC as Leds;
  
  MateContextSynch = Synch;
  MateAnalysis = Synch;
  ContextStatus = Synch;
  StdControl = Synch;

  Synch.CodeLocks = CodeLocks;
  Synch.MateError -> Error;
  Synch.Locks -> Locks;
  Synch.Queue -> Queue;
  Synch.Stacks -> Stacks;
  Synch.HandlerStore -> Store;
  Synch.Leds -> Leds;
  Synch.Bytecodes = Bytecodes;
  Synch.Scheduler -> VM;
}
  
