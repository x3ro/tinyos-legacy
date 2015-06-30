/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MOPcall {
  provides {
    interface MateBytecode as Exec;
    interface MateBytecode as ExecGlobal;
    interface MateBytecode as ExecPrimitive;
    interface MateBytecode as Return;
    interface MotlleVar as LV;
    interface MotlleVar as CV;
    interface MotlleVar as RawLV;
    interface MotlleVar as RawCV;
    interface MotlleClosure;
  }
  //uses interface MateBytecode as Primitives[uint16_t id];
}
implementation {
  components MOPcallM, MProxy, Memory, MotllePrimitives;

  Exec = MOPcallM.Exec;
  ExecGlobal = MOPcallM.ExecGlobal;
  ExecPrimitive = MOPcallM.ExecPrimitive;
  Return = MOPcallM.Return;
  LV = MOPcallM.LV;
  CV = MOPcallM.CV;
  RawLV = MOPcallM.RawLV;
  RawCV = MOPcallM.RawCV;
  MotlleClosure = MOPcallM;
  //Primitives = MOPcallM.Primitives;

  MOPcallM.InterpretFrame <- MProxy.MotlleFrame[MOTLLE_INTERPRET_FRAME];
  MOPcallM.GC -> MProxy;
  MOPcallM.S -> MProxy;
  MOPcallM.V -> MProxy;
  MOPcallM.T -> MProxy;
  MOPcallM.E -> MProxy;
  MOPcallM.G -> MProxy;
  MOPcallM.C -> MProxy;
  MOPcallM.HandlerStore -> Memory;

  MOPcallM.Primitives -> MotllePrimitives;
}
