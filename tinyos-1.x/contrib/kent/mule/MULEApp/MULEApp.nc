configuration MULEApp{
}
implementation {
  components Main, LedsC, MULEAppM, CC1000RadioIntM, 
  RadioCRCPacket as RadioPacket, UART, SysTimeC, MicC, Photo;

  Main.StdControl -> MULEAppM.StdControl;
  Main.StdControl -> UART;
  MULEAppM -> LedsC.Leds;
  MULEAppM.UARTByteComm -> UART;
  MULEAppM.RadioCoordinator -> CC1000RadioIntM.RadioSendCoordinator;

  MULEAppM.RadioControl -> RadioPacket;
  MULEAppM.RadioSend -> RadioPacket;
  MULEAppM.RadioReceive -> RadioPacket;

  MULEAppM.Mic -> MicC;
  MULEAppM.MicADC -> MicC;
  MULEAppM.MicControl-> MicC;
  MULEAppM.MicInterrupt -> MicC;

  MULEAppM.PhotoControl -> Photo;
  MULEAppM.PhotoADC -> Photo;

  MULEAppM.SysTime -> SysTimeC;

} 
