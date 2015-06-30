includes Mate;

configuration MDA300AD {
  provides {
    interface MateBytecode as Excite;
    interface MateBytecode as Adread;
  }
}
implementation {
  components MDA300ADM as Opcode, MStacksProxy, MErrorProxy, MTypesProxy,
    MQueueProxy, MContextSynchProxy, MateEngine as VM;
  components AnalogIOC;

  Excite = Opcode.Excite;
  Adread = Opcode.Adread;

  Opcode.Stacks -> MStacksProxy;
  Opcode.Types -> MTypesProxy;
  Opcode.Error -> MErrorProxy;
  Opcode.Queue -> MQueueProxy;
  Opcode.Synch -> MContextSynchProxy;
  Opcode.EngineStatus -> VM;

  Opcode.Sensor -> AnalogIOC;
  Opcode.Power -> AnalogIOC;
}
