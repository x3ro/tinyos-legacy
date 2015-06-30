/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration Memory
{
  provides {
    interface StdControl;
    interface MateHandlerStore as HandlerStore[uint8_t id];
    interface MotlleGC as GC;
    interface MotlleGlobals as G;
    interface MotlleStack as S;
    interface MateBytecode as Frame;
  }
  uses interface MotlleFrame[uint8_t kind];
}
implementation {
  components MemoryM, MProxy, MContextSynchProxy, MVirusProxy, MateEngine;
  components HPLPowerManagementM;

  StdControl = MemoryM;
  HandlerStore = MemoryM;
  GC = MemoryM;
  G = MemoryM;
  S = MemoryM;
  MotlleFrame = MemoryM;
  Frame = MemoryM;

  MemoryM.V -> MProxy;
  MemoryM.T -> MProxy;
  MemoryM.E -> MProxy;

  MemoryM.Virus -> MVirusProxy;
  MemoryM.EngineControl <- MateEngine.EngineControl;

  MemoryM.PowerMgmtEnable -> HPLPowerManagementM.Enable;
}
