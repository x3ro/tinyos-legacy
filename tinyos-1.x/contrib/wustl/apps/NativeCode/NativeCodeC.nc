includes NativeCode;

configuration NativeCodeC {
}
implementation {
  components Main, NativeCodeM, GenericComm, LedsC;
  
  Main.StdControl -> NativeCodeM;
  Main.StdControl -> GenericComm;
  NativeCodeM.ReceiveState -> GenericComm.ReceiveMsg[AM_STATEMSG];
  NativeCodeM.ReceiveCode -> GenericComm.ReceiveMsg[AM_CODEMSG];
  NativeCodeM.SendState -> GenericComm.SendMsg[AM_STATEMSG];
  NativeCodeM.SendCode -> GenericComm.SendMsg[AM_CODEMSG];  
  NativeCodeM.Leds -> LedsC;
}
