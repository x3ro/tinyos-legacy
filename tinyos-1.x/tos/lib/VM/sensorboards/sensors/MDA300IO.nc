includes Mate;

configuration MDA300IO {
  provides {
    interface MateBytecode as EnableTrigger;
    interface MateBytecode as SetPinDirection;
    interface MateBytecode as ReadPin;
    interface MateBytecode as WritePin;
  }
}
implementation {
  components MDA300IOM as Opcode, MStacksProxy, MErrorProxy, MTypesProxy,
    MQueueProxy, MContextSynchProxy, MateEngine as VM;
  components DigitalIOC;

  EnableTrigger = Opcode.EnableTrigger;
  SetPinDirection = Opcode.SetPinDirection;
  ReadPin = Opcode.ReadPin;
  WritePin = Opcode.WritePin;

  Opcode.Stacks -> MStacksProxy;
  Opcode.Types -> MTypesProxy;
  Opcode.Error -> MErrorProxy;
  Opcode.Queue -> MQueueProxy;
  Opcode.Synch -> MContextSynchProxy;
  Opcode.Analysis -> MContextSynchProxy;
  Opcode.EngineStatus -> VM;

  Opcode.DigitalIO -> DigitalIOC;
  Opcode.DigitalControl -> DigitalIOC;
  VM.SubControl -> Opcode;
}
