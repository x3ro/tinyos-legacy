/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
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
 */
/*									tab:4
 *									
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *  By downloading, copying, installing or using the software you
 *  agree to this license.  If you do not agree to this license, do
 *  not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2004 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/*
 * Authors:   Neil Patel, Philip Levis
 * History:   Apr 11, 2003         Inception.
 *
 */

/**
 * @author Neil Patel
 * @author Philip Levis
 */


includes Mate;

configuration MateEngine {
  provides {
    interface StdControl;    
    interface MateError as Error;
    interface MateEngineStatus as EngineStatus;
    interface MateScheduler as Scheduler;
    interface MateBytecode as Functions[uint8_t functionID];
  }
  uses {
    interface MateEngineControl as EngineControl;
    interface MateBytecode as Bytecode[uint8_t bytecode];
    interface MateBytecode as FunctionImpls[uint8_t fnID];
    interface StdControl as SubControl;
  }
}

implementation {
  components MateEngineM as VM;
  components LedsC, TimerC, QueuedSend as SendComm;
  components MContextSynchProxy as Synch;
  components MQueueProxy as Queue;
  components MHandlerStoreProxy as HandlerStore;

  // The initializations
  StdControl = VM;
  EngineControl = VM.EngineControl;
  Error = VM.Error;
  EngineStatus = VM.EngineStatus;
  Scheduler = VM.Scheduler;
  /****** SUBSYSTEMS ********/

  VM.SubControl = SubControl;

  // Queue ADT component
  VM.Queue -> Queue;
  
  // Synchronization component
  VM.Synch -> Synch;
  VM.Analysis -> Synch;
  VM.SubControl -> Synch;
  
  // Instruction set
  Bytecode = VM.BytecodeImpls;
  Synch.Bytecodes -> VM.Bytecodes;
  VM.Functions = Functions;
  VM.FunctionImpls = FunctionImpls;
  
  // Error subsystem
  VM.Leds -> LedsC;
  VM.SubControl -> TimerC;
  VM.ErrorTimer -> TimerC.Timer[unique("Timer")];
  //VM.SubControl -> SendComm;
  VM.SendError -> SendComm.SendMsg[AM_MATEERRORMSG];
  VM.HandlerStore -> HandlerStore;
}
