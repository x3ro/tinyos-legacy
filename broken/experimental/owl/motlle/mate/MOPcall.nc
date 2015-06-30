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
  components MOPcallM, MProxy, MotllePrimitives;

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

  MOPcallM.Primitives -> MotllePrimitives;
}
